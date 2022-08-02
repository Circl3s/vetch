module getters

import os
import term

const icons = {
	"user": term.bold(term.red("\uf007 ") + "user\t\t│ ")
	"host": term.bold(term.yellow("\uf878 ") + "host\t\t│ ")
	"linux": term.bold(term.blue("\uf17c ") + "os\t\t│ ")
	"windows": term.bold(term.blue("\uf17a ") + "os\t\t│ ")
	"macos": term.bold(term.blue("\uf179 ") + "os\t\t│ ")
	"term": term.bold(term.cyan("\uf2d0 ") + "terminal\t│ ")
	"shell": term.bold(term.green("\uf120 ") + "shell\t\t│ ")
	"ver": term.bold(term.magenta("\uf02b ") + "kernel\t│ ")
	"cpu": term.bold(term.red("\uf85a ") + "cpu\t\t│ ")
	"gpu": term.bold(term.yellow("\ufcfb ") + "gpu\t\t│ ")
	"disk": term.bold(term.blue("\uf7c9 ") + "space\t\t│ ")
	"mem": term.bold(term.green("\ufb19 ") + "memory\t\t│ ")
}

pub fn user() string {
	return icons["user"] + os.loginname()
}

pub fn host() string {
	if os.user_os() == "windows" {
		return icons["host"] + os.execute("hostname").output.trim_space()
	} else {
		return icons["host"] + os.hostname().trim_space()
	}
}

pub fn os() string {
	return icons[os.user_os()] + os.uname().sysname.trim_space()
}

pub fn version() string {
	return icons["ver"] + os.uname().release.trim_space()
}

pub fn cpu() string {
	if os.user_os() == "windows" {
		return icons["cpu"] + os.execute("wmic cpu get name").output.split("\n")[1].trim_space() + " (${os.execute("wmic cpu get numberofcores").output.split("\n")[1].trim_space()} cores / ${os.execute("wmic cpu get numberoflogicalprocessors").output.split("\n")[1].trim_space()} threads)"
	} else {
		lines := os.read_lines("/proc/cpuinfo") or {
			return icons["cpu"] + "Unknown"
		}
		return icons["cpu"] + lines[4].split(":")[1].trim_space() + " (${lines[12].split(":")[1].trim_space()} cores / ${lines[10].split(":")[1].trim_space()} threads"
	}
}

pub fn gpu() ?string {
	if os.user_os() == "windows" {
		return icons["gpu"] + os.execute("wmic path win32_VideoController get name").output.split("\n")[1].trim_space()
	} else {
		return none
	}
}

pub fn term() ?string {
	if os.getenv("TERM_PROGRAM") != "" {
		return icons["term"] + os.getenv("TERM_PROGRAM").trim_space()
	} else if os.getenv("SSH_TTY") != "" {
		return icons["term"] + "tty"
	} else {
		return none
	}
}

pub fn shell() ?string {
	if os.user_os() == "windows" {
		//TODO: Figure out windows shell
		if os.getenv("STARSHIP_SHELL") != "" {
			return icons["shell"] + os.getenv("STARSHIP_SHELL").trim_space()
		} else {
			return none
		}
	} else {
		return icons["shell"] + os.getenv("SHELL").trim_space()
	}
}

pub fn divider() string {
	return term.bold("\t\t│")
}