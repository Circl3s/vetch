module main

import getters as get

fn main() {
	println(get.user())
	println(get.host())
	println(get.os())
	println(get.version())
	println(get.term()?)
	println(get.shell()?)
	println(get.divider())
	println(get.cpu())
	println(get.gpu()?)
}
