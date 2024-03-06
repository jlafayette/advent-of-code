package day12

import "core:fmt"

Level :: enum {
	Debug,
	Info,
	Warning,
	Error,
}
level: Level = .Warning
indent_log := 0

_log :: proc(args: ..any, sep := " ", flush := true) {
	if indent_log > 0 {
		for i := indent_log; i > 0; i -= 1 {
			fmt.print(" ", flush = false)
		}
	}
	fmt.println(..args, sep = sep, flush = flush)
}

log_debug :: proc(args: ..any, sep := " ", flush := true) {
	switch level {
	case .Debug:
		{
			_log(..args, sep = sep, flush = flush)
		}
	case .Info:
	case .Warning:
	case .Error:
	}
}
log_info :: proc(args: ..any, sep := " ", flush := true) {

	switch level {
	case .Debug:
		fallthrough
	case .Info:
		{
			_log(..args, sep = sep, flush = flush)
		}
	case .Warning:
	case .Error:
	}
}
log_warning :: proc(args: ..any, sep := " ", flush := true) {
	switch level {
	case .Debug:
		fallthrough
	case .Info:
		fallthrough
	case .Warning:
		{
			_log(..args, sep = sep, flush = flush)
		}
	case .Error:
	}
}
log_error :: proc(args: ..any, sep := " ", flush := true) {
	_log(..args, sep = sep, flush = flush)
}
