local wezterm = require("wezterm")
local C = require("constants")

local M = {}

function M.apply(cfg)
	if not wezterm.gui then
		return
	end

	-- Keep a high-refresh WebGPU path for the discrete-GPU machine and a
	-- conservative OpenGL path for the integrated-GPU machine.
	local preferred = C.GRAPHICS.preferred
	for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
		if gpu.device_type == preferred.device_type and gpu.backend == preferred.backend then
			cfg.max_fps = preferred.max_fps
			cfg.front_end = preferred.front_end
			cfg.webgpu_preferred_adapter = gpu
			cfg.webgpu_power_preference = preferred.power_preference
			return
		end
	end

	cfg.max_fps = C.GRAPHICS.fallback.max_fps
	cfg.front_end = C.GRAPHICS.fallback.front_end
end

return M
