package main

import (
	tea "charm.land/bubbletea/v2"
	"encoding/json"
	"fmt"
	"github.com/charmbracelet/lipgloss"
	"github.com/common-nighthawk/go-figure"
	"io"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

type model struct {
	choices    []string
	cursor     int
	selected   map[int]struct{}
	state      string
	password   string
}

func runAsSudo(command []string, password string) {
	cmd := exec.Command("sudo", append([]string{"-S"}, command...)...)
	cmd.Stdin = strings.NewReader(password + "\n")
	cmd.Run()
}

func initialModel() model {
	themodel := model{
		choices:    []string{"Install"},
		cursor:     0,
		selected:   make(map[int]struct{}),
		state:      "menu",
	}
	_, err := os.Stat("/bin/bcsh")
	if err == nil {
		themodel.choices = []string{"Update", "Uninstall"}
	}
	return themodel
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		if m.state == "password" {
			switch msg.String() {
			case "backspace":
				if len(m.password) > 0 {
					m.password = m.password[:len(m.password)-1]
				}
			case "enter":
				if m.choices[m.cursor] == "Install" || m.choices[m.cursor] == "Update" {
					m.install()
				}
				if m.choices[m.cursor] == "Uninstall" {
					m.uninstall()
				}
				m.state = "done"
			default:
				m.password += msg.String()
			}
			return m, nil
		}
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.choices)-1 {
				m.cursor++
			}
		case "enter", "space":
			m.state = "password"
			m.password = ""
		}
	}
	return m, nil
}

var (
	borderStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			Padding(3, 6).
			BorderForeground(lipgloss.Color("63"))
	titleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("39")).
			Bold(true)
	selectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("42")).
			Bold(true)
	choiceStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))
	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241"))
	menuStyle = lipgloss.NewStyle().Align(lipgloss.Center)
)

func (m model) View() tea.View {
	s := figure.NewFigure("BCSH Installer", "", true).String() + "\n\n"
	if m.state == "menu" {
		for i, choice := range m.choices {
			cursor := " "
			if m.cursor == i {
				cursor = ">"
			}
			s += menuStyle.Render(fmt.Sprintf("%s %s", cursor, choice)) + "\n"
		}
	} else if m.state == "password" {
		s += "Sudo Password:\n\n"
		s += "> " + strings.Repeat("*", len(m.password))
		s += "\n\nPress Enter to continue."
	}

	s += "\nPress q to quit.\n"
	v := tea.NewView(borderStyle.Render(s))
	v.WindowTitle = "BCSH Installer"
	v.AltScreen = true
	return v
}

func (m model) install() {
	arch := runtime.GOARCH
	binary := ""
	switch arch {
	case "amd64":
		binary = "bcsh-x86_64"
	case "arm64":
		binary = "bcsh-arm64"
	case "arm":
		binary = "bcsh-armhf"
	case "386":
		binary = "bcsh-i386"
	case "mips":
		binary = "bcsh-mips"
	case "mipsle":
		binary = "bcsh-mipsel"
	case "ppc64":
		binary = "bcsh-ppc64"
	case "ppc64le":
		binary = "bcsh-ppc64le"
	case "riscv64":
		binary = "bcsh-riscv64"
	case "s390x":
		binary = "bcsh-s390x"
	}
	api := "https://git.bestcoder1877.qzz.io/api/v1/repos/bestCoder1877/bcsh/releases/latest"
	resp, _ := http.Get(api)
	var release struct {
		TagName string `json:"tag_name"`
	}
	json.NewDecoder(resp.Body).Decode(&release)
	resp.Body.Close()
	url := "https://git.bestcoder1877.qzz.io/bestCoder1877/bcsh/releases/download/" + release.TagName + "/" + binary
	resp, _ = http.Get(url)
	file, _ := os.Create("bcsh")
	io.Copy(file, resp.Body)
	file.Close()
	resp.Body.Close()
	os.Chmod("bcsh", 0755)
	runAsSudo([]string{"sudo", "install", "-m", "755", "bcsh", "/bin/bcsh"}, m.password)
	runAsSudo([]string{"sudo", "sh", "-c", `grep -qx "/bin/bcsh" /etc/shells || echo "/bin/bcsh" >> /etc/shells`}, m.password)
	os.Remove("bcsh")
}

func (m model) uninstall() {
	runAsSudo([]string{"sudo", "rm", "-f", "/bin/bcsh"}, m.password)
	runAsSudo([]string{"sudo", "sed", "-i", `\|^/bin/bcsh$|d`, "/etc/shells"}, m.password)
}

func main() {
	p := tea.NewProgram(initialModel())
	p.Run()
}
