local wezterm = require("wezterm")

local M = {}

function M.apply(cfg)
	if not wezterm.gui then
		return
	end

	for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
		if gpu.device_type == "DiscreteGpu" and gpu.backend == "Dx12" then
			cfg.max_fps = 165
			cfg.front_end = "WebGpu"
			cfg.webgpu_preferred_adapter = gpu
			cfg.webgpu_power_preference = "HighPerformance"
			return
		end
	end

	cfg.max_fps = 120
	cfg.front_end = "OpenGL"
end

return M
