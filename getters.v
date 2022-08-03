module getters

import os
import term
import json
import math as maths

struct Lsblk {
	blockdevices []BlockDevice
}

struct BlockDevice {
	name string
	majmin string [json: "maj:min"]
	rm bool
	size string
	ro bool
	blk_type string [json: "type"]
	mountpoint string
	children []BlockDevice
}

struct PSResult {
	cpu string
	cores int
	threads int
	gpu string
	mem []i64
	uptime int
	disks []Disk
}

struct Disk {
	name string
	size i64
	free i64
}

const ps_script = r"$CPU = (Get-CimInstance -Query 'SELECT Name, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor')
$GPU = (Get-CimInstance -Query 'SELECT Caption FROM Win32_VideoController')
$MEM = (Get-CimInstance -Query 'SELECT Capacity FROM Win32_PhysicalMemory')
$BOOT = (Get-CimInstance -Query 'SELECT LastBootUpTime FROM Win32_OperatingSystem')
$DISKS_RAW = (Get-CimInstance -Query 'SELECT Size, FreeSpace, Caption FROM Win32_LogicalDisk WHERE DriveType=3')
$DISKS = @()
foreach ($Disk in $DISKS_RAW) {
    $DISKS = $DISKS + @{
        name = $Disk.Caption
        size = $Disk.Size
        free = $Disk.FreeSpace
    }
}
$Result = @{
    cpu = $CPU.Name
    cores = $CPU.NumberOfCores
    threads = $CPU.NumberOfLogicalProcessors
    gpu = $GPU.Caption
    mem = $MEM.Capacity
    uptime = ((Get-Date) - $BOOT.LastBootUpTime).TotalSeconds
    disks = $DISKS
}
Write-Output (ConvertTo-Json $Result)"

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
	"disk": term.bold(term.blue("\uf7c9 ") + "storage\t│ ")
	"mem": term.bold(term.green("\ufb19 ") + "memory\t│ ")
	"uptime": term.bold(term.green("\uf017 ") + "uptime\t│ ")
	"colors": term.bold(term.cyan("\ue22b ") + "colors\t│ ")
}

pub struct Getter {
	lsblk Lsblk
	ps_result PSResult
}

pub fn new_getter() Getter {
	return Getter{
		lsblk: if os.user_os() == "linux" {
			json.decode(Lsblk, os.execute("lsblk --json").output) or {
				Lsblk{}
			}
		} else {
			Lsblk{}
		}
		ps_result: if os.user_os() == "windows" {
			os.write_file("./vetch.ps1", ps_script) or {
				panic(err)
			}
			defer {
				os.rm("./vetch.ps1") or {}
			}
			json.decode(PSResult, os.execute('powershell -NoProfile ./vetch.ps1').output) or {
				PSResult{}
			}
		} else {
			PSResult{}
		}
	}
}

pub fn (g Getter) user() string {
	return icons["user"] + os.loginname() + "\n"
}

pub fn (g Getter) host() string {
	if os.user_os() == "windows" {
		return icons["host"] + os.execute("hostname").output.trim_space() + "\n"
	} else {
		return icons["host"] + os.hostname().trim_space() + "\n"
	}
}

pub fn (g Getter) os() string {
	return icons[os.user_os()] + os.uname().sysname.trim_space() + " (" + os.uname().machine.trim_space() + ")\n"
}

pub fn (g Getter) version() string {
	return icons["ver"] + os.uname().release.trim_space() + "\n"
}

pub fn (g Getter) cpu() string {
	if os.user_os() == "windows" {
		return icons["cpu"] + "${g.ps_result.cpu} (${g.ps_result.cores} cores / ${g.ps_result.threads} threads)\n"
	} else {
		lines := os.execute("cat /proc/cpuinfo").output.split("\n")
		return icons["cpu"] + lines[4].split(":")[1].trim_space() + " (${lines[12].split(":")[1].trim_space()} cores / ${lines[10].split(":")[1].trim_space()} threads)" + "\n"
	}
}

pub fn (g Getter) gpu() string {
	if os.user_os() == "windows" {
		return icons["gpu"] + g.ps_result.gpu + "\n"
	} else {
		return ""
	}
}

pub fn (g Getter) term() string {
	if os.getenv("TERM_PROGRAM") != "" {
		return icons["term"] + os.getenv("TERM_PROGRAM").trim_space() + "\n"
	} else {
		return ""
	}
}

pub fn (g Getter) shell() string {
	mut shell := ""
	match true {
		os.getenv("SHELL") != "" {
			shell = os.getenv("SHELL")
		}
		os.getenv("STARSHIP_SHELL") != "" {
			shell = os.getenv("STARSHIP_SHELL")
		}
		else {
			shell = ""
		}
	}
	if shell != "" {
		return icons["shell"] + shell.split(if os.user_os() == "windows" {"\\"} else {"/"}).last().trim_space() + "\n"
	} else {
		return ""
	}
}

pub fn (g Getter) memory() string {
	if os.user_os() == "windows" {
		mems :=	g.ps_result.mem
		mut total := i64(0)
		for cap in mems {
			total += cap
		}
		return icons["mem"] + (total / 1024 / 1024 / 1024).str() + "GB\n"
	} else {
		total := (os.execute("cat /proc/meminfo").output.split("\n")[0].split(":")[1].trim_space()#[..-3]).f64()
		return icons["mem"] + maths.ceil((total / 1024 / 1024)).str()#[..-1] + "GB\n"
	}
}

fn bar(free i64, total i64) string {
	ratio := int(maths.round(f64(free) / f64(total) * 20))
	used_blocks := 20 - ratio
	free_string := "${free / 1024 / 1024 / 1024}G free"
	total_string := "${total / 1024 / 1024 / 1024}G total"
	start := 20 - free_string.len
	mut final_string := ""
	for i in 0 .. 20 {
		if i < used_blocks {
			if i >= start {
				final_string += term.bg_red(term.black(rune(free_string[i - start]).str()))
			} else {
				final_string += term.red("█")
			}
		} else {
			if i >= start {
				final_string += term.bg_green(term.black(rune(free_string[i - start]).str()))
			} else {
				final_string += term.green("█")
			}
		}
	}
	return final_string + " / $total_string"
}

pub fn (g Getter) storage() string {
	if os.user_os() == "windows" {
		disks := g.ps_result.disks
		mut final_string :=  ""
		for i, disk in disks {
			final_string += if i == 1 {icons["disk"]} else {term.bold("\t\t│ ")} + "${disk.name} ${bar(disk.free, disk.size)}\n"
		}
		return final_string
	} else {
		lsblk := g.lsblk
		disks := lsblk.blockdevices.filter(it.blk_type == "disk")
		mut parts := []BlockDevice{}
		for disk in disks {
			for part in disk.children {
				parts << part
			}
		}
		parts = parts.filter(it.mountpoint != "")
		mut final_string := ""
		for i, part in parts {
			free := os.execute("df $part.mountpoint --output=avail").output.split("\n")[1].trim_space().i64()
			total := os.execute("df $part.mountpoint --output=size").output.split("\n")[1].trim_space().i64()
			final_string += if i == 1 {icons["disk"]} else {term.bold("\t\t│ ")} + "${part.mountpoint}\t ${bar(free, total)} / ${part.size}\n"
		}
		return final_string
	}
}

pub fn (g Getter) uptime() string {
	if os.user_os() == "windows" {
		total_seconds := g.ps_result.uptime
		total_hours := total_seconds / 60 / 60
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

pub fn (g Getter) colors() string {
	return icons["colors"] + term.bright_magenta("██") + term.bright_red("██") + term.bright_yellow("██") + term.bright_green("██") + term.bright_cyan("██") + term.bright_blue("██") + term.bright_white("██") + term.bright_black("██") + term.bold("\n\t\t│ ") + term.magenta("██") + term.red("██") + term.yellow("██") + term.green("██") + term.cyan("██") + term.blue("██") + term.white("██") + term.black("██\n")
}

pub fn (g Getter) divider() string {
	return term.bold("\t\t│\n")
}
