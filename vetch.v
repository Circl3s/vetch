module main

import getters

fn main() {
	get := getters.new_getter() or {
		println(err)
		return
	}
	print(get.user())
	print(get.host())
	print(get.uptime())
	print(get.os())
	print(get.version())
	print(get.term())
	print(get.shell())
	print(get.divider())
	print(get.cpu())
	print(get.gpu())
	print(get.memory())
	print(get.storage())
	print(get.divider())
	print(get.colors())
}
