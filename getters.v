module getters

import os
import term
import math as maths

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
	"mem": term.bold(term.green("\ufb19 ") + "memory\t│ ")
	"uptime": term.bold(term.green("\uf017 ") + "uptime\t│ ")
}

pub fn user() string {
	return icons["user"] + os.loginname() + "\n"
}

pub fn host() string {
	if os.user_os() == "windows" {
		return icons["host"] + os.execute("hostname").output.trim_space() + "\n"
	} else {
		return icons["host"] + os.hostname().trim_space() + "\n"
	}
}

pub fn os() string {
	return icons[os.user_os()] + os.uname().sysname.trim_space() + "\n"
}

pub fn version() string {
	return icons["ver"] + os.uname().release.trim_space() + "\n"
}

pub fn cpu() string {
	if os.user_os() == "windows" {
		return icons["cpu"] + os.execute("wmic cpu get name").output.split("\n")[1].trim_space() + " (${os.execute("wmic cpu get numberofcores").output.split("\n")[1].trim_space()} cores / ${os.execute("wmic cpu get numberoflogicalprocessors").output.split("\n")[1].trim_space()} threads)" + "\n"
	} else {
		lines := os.execute("cat /proc/cpuinfo").output.split("\n")
		return icons["cpu"] + lines[4].split(":")[1].trim_space() + " (${lines[12].split(":")[1].trim_space()} cores / ${lines[10].split(":")[1].trim_space()} threads)" + "\n"
	}
}

pub fn gpu() string {
	if os.user_os() == "windows" {
		return icons["gpu"] + os.execute("wmic path win32_VideoController get name").output.split("\n")[1].trim_space() + "\n"
	} else {
		return ""
	}
}

pub fn term() string {
	if os.getenv("TERM_PROGRAM") != "" {
		return icons["term"] + os.getenv("TERM_PROGRAM").trim_space() + "\n"
	} else {
		return ""
	}
}

pub fn shell() string {
	if os.user_os() == "windows" {
		//TODO: Figure out windows shell
		if os.getenv("STARSHIP_SHELL") != "" {
			return icons["shell"] + os.getenv("STARSHIP_SHELL").trim_space() + "\n"
		} else {
			return ""
		}
	} else {
		return icons["shell"] + os.getenv("SHELL").trim_space() + "\n"
	}
}

pub fn memory() string {
	if os.user_os() == "windows" {
		mems :=	os.execute("wmic memorychip get capacity").output.split("\n")[1..]
		mut total := i64(0)
		for cap in mems {
			total += cap.trim_space().i64()
		}
		return icons["mem"] + (total / 1024 / 1024 / 1024).str() + "GB\n"
	} else {
		total := (os.execute("cat /proc/meminfo").output.split("\n")[0].split(":")[1].trim_space()#[..-3]).f64()
		return icons["mem"] + maths.ceil((total / 1024 / 1024)).str()#[..-1] + "GB\n"
	}
}

pub fn uptime() string {
	if os.user_os() == "windows" {
		total_hours := os.execute('powershell -NoProfile "$(((Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime))).TotalHours)"').output.int()
		days := total_hours / 24
		hours := total_hours % 24
		return icons["uptime"] + "$days days, $hours hours\n"
	} else {
		total_seconds := os.execute("cat /proc/uptime").output.split(" ")[0].int()
		total_hours := total_seconds / 60 / 60
		days := total_hours / 24
		hours := total_hours % 24
		return icons["uptime"] + "$days days, $hours hours\n"
	}
}

pub fn divider() string {
	return term.bold("\t\t│\n")
}
