package day12

import "core:fmt"

Level :: enum {
	Debug,
	Info,
	Warning,
	Error,
}
level: Level = .Warning

log_debug :: proc(args: ..any, sep := " ", flush := true) {
	switch level {
	case .Debug:
		{
			fmt.println(..args, sep = sep, flush = flush)
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
			fmt.println(..args, sep = sep, flush = flush)
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
			fmt.println(..args, sep = sep, flush = flush)
		}
	case .Error:
	}
}
log_error :: proc(args: ..any, sep := " ", flush := true) {
	fmt.println(..args, sep = sep, flush = flush)
}
