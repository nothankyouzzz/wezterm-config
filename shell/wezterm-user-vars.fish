if not status is-interactive
	return
end

if test "$TERM_PROGRAM" != "WezTerm"
	return
end

function __wezterm_emit_user_var --argument-names name value
	if not type -q base64
		return
	end

	set -l encoded (printf '%s' "$value" | base64 | tr -d '\r\n')
	printf '\e]1337;SetUserVar=%s=%s\a' "$name" "$encoded"
end

function __wezterm_set_static_user_vars
	__wezterm_emit_user_var WEZTERM_USER (id -un)
	__wezterm_emit_user_var WEZTERM_HOST (hostname)
end

function __wezterm_set_prog_var --argument-names commandline
	__wezterm_emit_user_var WEZTERM_PROG "$commandline"
end

function __wezterm_set_prompt_prog_var
	__wezterm_set_prog_var (status fish-path)
end

function __wezterm_user_vars_preexec --on-event fish_preexec
	__wezterm_set_prog_var "$argv[1]"
end

function __wezterm_user_vars_postexec --on-event fish_postexec
	__wezterm_set_prompt_prog_var
end

function __wezterm_user_vars_prompt --on-event fish_prompt
	__wezterm_set_prompt_prog_var
end

__wezterm_set_static_user_vars
__wezterm_set_prompt_prog_var
