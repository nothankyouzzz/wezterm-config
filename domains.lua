local wezterm = require("wezterm")
local C = require("constants")

local M = {}

local function matches_distribution(distribution, preference)
	if not preference or not preference.value or distribution == nil then
		return false
	end

	if preference.type == "exact" then
		return distribution == preference.value
	end

	return distribution:match(preference.value) ~= nil
end

local function preferred_default_domain()
	local wsl_domains = wezterm.default_wsl_domains()
	for _, preference in ipairs(C.WSL.preferred_distributions or {}) do
		for _, domain in ipairs(wsl_domains) do
			if matches_distribution(domain.distribution, preference) then
				return domain.name
			end
		end
	end

	return nil
end

local function resolved_ssh_domain(spec)
	local domain = {
		name = spec.name,
		remote_address = spec.remote_address,
		username = spec.username,
	}

	local multiplexing = spec.multiplexing
	if multiplexing == nil and spec.remote_wezterm_path then
		multiplexing = "WezTerm"
	end
	multiplexing = multiplexing or "None"

	if multiplexing == "WezTerm" then
		domain.multiplexing = "WezTerm"
		domain.remote_wezterm_path = spec.remote_wezterm_path or "wezterm"
	else
		domain.multiplexing = "None"
		if spec.assume_shell then
			domain.assume_shell = spec.assume_shell
		end
	end

	return domain
end

local function upsert_domain(domains, domain)
	for index, existing in ipairs(domains) do
		if existing.name == domain.name then
			domains[index] = domain
			return
		end
	end

	table.insert(domains, domain)
end

function M.apply(cfg)
	local default_domain = preferred_default_domain()
	if default_domain then
		cfg.default_domain = default_domain
	end

	local ssh_domains = wezterm.default_ssh_domains()
	for _, spec in ipairs(C.SSH.custom_domains or {}) do
		upsert_domain(ssh_domains, resolved_ssh_domain(spec))
	end

	cfg.ssh_domains = ssh_domains
end

return M
