-- const
-- 
-- keys
key_left = 0
key_right = 1
key_up = 2
key_down = 3
key_jump = 4
key_dash = 5

-- color
c00 = 0
c01 = 1
c02 = 2
c03 = 3
c04 = 4
c05 = 5
c06 = 6
c07 = 7
c08 = 8
c09 = 9
c10 = 10
c11 = 11
c12 = 12
c13 = 13
c14 = 14
c15 = 15

-- directions
dir_left = { x = -1, y = 0 }
dir_right = { x = 1, y = 0 }
dir_up = { x = 0, y = -1 }
dir_down = { x = 0, y = 1 }

-- level
lv_peaceful = 1
lv_normal = 2
lv_hard = 3

-- weight
w0 = 0
w1 = 1
w2 = 2
w3 = 3
w4 = 4
w5 = 5
w6 = 6
w7 = 7
w8 = 8
w9 = 9

-- other
fps = 30
scn_len = 16
-- 

-- global variables
-- 
tick = true
frame = 0
score = 0
cur_lv = 0
foods = {}
-- 

-- for debug output
debug = true
bug = 0

-- snake
-- 
snake = {
	dir = {
		x = 0,
		y = 0,
		buffer = { x = 0, y = 0 }
	},
	speed = 3,
	parts = {},
	head = { x = 4, y = 4, front = { x = 0, y = 0 }, spr = c11 },
	tail = {},
	can_move = false,
	is_dead = false,
	dead_part = {},
	die_effect_speed = 15,
	grow = function()
		if is_empty(snake.tail) then
			snake.tail = deep_copy(snake.head)
			coordinate_copy(snake.head, snake.tail.front)
			snake.tail.prev = snake.head
			snake.tail.spr = c03
			add(snake.parts, snake.tail)
		else
			local new_body = deep_copy(snake.tail)
			new_body.prev = snake.tail.prev
			add(snake.parts, new_body)
			coordinate_copy(new_body, snake.tail.front)
			snake.tail.prev = new_body
		end
	end,
	die = function()
		snake.is_dead = true
		level[cur_lv].on_snake_died()
	end,
	die_effect = function()
		if frame % (fps \ snake.die_effect_speed) ~= 0 then
			return
		end
		if next(snake.dead_part) == nil then
			snake.dead_part = snake.tail
		elseif snake.dead_part.prev ~= nil then
			snake.dead_part = snake.dead_part.prev
		end
		snake.dead_part.spr = c14
		if snake.dead_part.prev == nil then
			snake.dead_part.spr = c08
		end
	end,
	move = function()
		snake.head.front.x = snake.head.x + snake.dir.x
		snake.head.front.y = snake.head.y + snake.dir.y
		loop(snake.head.front)
		foreach(
			snake.parts,
			function(part)
				if part ~= snake.head and overlap(part, snake.head.front) then
					snake.die()
				end
			end
		)
		if snake.is_dead then
			return
		end
		foreach(
			snake.parts,
			function(part)
				if not overlap(part, part.front) then
					part.x = part.front.x
					part.y = part.front.y
				end
			end
		)
	end,
	init = function()
		add(snake.parts, snake.head)
	end,
	update = function()
		if frame % (fps \ snake.speed) == 0 then
			snake.can_move = true
		else
			snake.can_move = false
		end
		if not overlap(snake.dir, dir_left) and btnp(key_right) then
			coordinate_copy(dir_right, snake.dir.buffer)
		elseif not overlap(snake.dir, dir_right) and btnp(key_left) then
			coordinate_copy(dir_left, snake.dir.buffer)
		elseif not overlap(snake.dir, dir_up) and btnp(key_down) then
			coordinate_copy(dir_down, snake.dir.buffer)
		elseif not overlap(snake.dir, dir_down) and btnp(key_up) then
			coordinate_copy(dir_up, snake.dir.buffer)
		end


		-- debug
		if debug then
			if btnp(key_dash) then
				snake.grow()
			end
		end

		if snake.can_move and not snake.is_dead then
			coordinate_copy(snake.dir.buffer, snake.dir)
			snake.move()
		elseif snake.is_dead then
			snake.die_effect()
		end
		foreach(
			snake.parts,
			function(part)
				if part.prev ~= nil then
					coordinate_copy(part.prev, part.front)
				end
			end
		)
	end,
	draw = function()
		foreach(
			snake.parts,
			function(part)
				spr(part.spr, to_tile(part.x), to_tile(part.y))
			end
		)
		spr(snake.head.spr, to_tile(snake.head.x), to_tile(snake.head.y))
	end
}
-- 

-- food spawner
-- 
food_spawner = {
	kind = {
		first = { cur = 0, max = 0, types = {} },
		second = { cur = 0, max = 0, types = {} },
		third = { cur = 0, max = 0, type = {} }
	},
	on_food_eaten = function(food)
		local first = food_spawner.kind.first
		local second = food_spawner.kind.second
		local third = food_spawner.kind.third
		if has(first.types, food.type) then
			first.cur -= 1
		end
		if has(second.types, food.type) then
			second.cur -= 1
		end
		if has(third.types, food.type) then
			third.cur -= 1
		end
		level[cur_lv].on_food_eaten(food)
	end,
	replenish = function()
		local first = food_spawner.kind.first
		local second = food_spawner.kind.second
		local third = food_spawner.kind.third
		while first.cur < first.max do
			food_spawner.spawn(rnd_weighted(first.types))
			first.cur += 1
		end
		while second.cur < second.max do
			food_spawner.spawn(rnd_weighted(second.types))
			second.cur += 1
		end
		while third.cur < third.max do
			food_spawner.spawn(rnd_weighted(third.types))
			third.cur += 1
		end
	end,
	spawn = function(type, pos)
		local food = {}
		local dft_pos = pos and not is_snake_at(pos) and pos or nil
		local try_cnt = 0
		while true do
			coordinate_copy(dft_pos or { x = flr(rnd(scn_len)), y = flr(rnd(scn_len)) }, food)
			try_cnt += 1
			if try_cnt >= 10 then
				return
			end
			if not is_snake_at(food) and not is_food_at(food) then
				break
			end
		end
		food.type = type
		add(foods, food)
	end,
	init = function()
		food_spawner.replenish()
	end
}
-- 

-- food type
-- 
-- 
-- mate table for function
food_function = {
	eaten = function(food)
		del(foods, food)
		food.type.eaten_effect()
		food_spawner.on_food_eaten(food)
	end,
	update = function(food)
		if overlap(food, snake.head) then
			food.type.eaten(food)
		end
	end,
	draw = function(food)
		spr(food.type.spr, to_tile(food.x), to_tile(food.y))
	end
}
food_function.__index = food_function

-- first
-- 
-- score = 1
ordinary_food = {
	weight = w0,
	spr = c07,
	eaten_effect = function()
		score += 1
		sfx(0)
	end
}
setmetatable(ordinary_food, food_function)
add(food_spawner.kind.first.types, ordinary_food)

-- score = 2
score_food = {
	weight = w0,
	spr = c06,
	eaten_effect = function()
		score += 2
		sfx(0)
	end
}
setmetatable(score_food, food_function)
add(food_spawner.kind.first.types, score_food)
-- 
-- 
-- 

-- level
-- 
level = {
	[lv_peaceful] = {
		food_kind = {
			first = {
				to = food_spawner.kind.first,
				max = 3,
				types = {
					{ to = ordinary_food, weight = w1 },
					{ to = score_food, weight = w1 }
				}
			},
			second = {
				to = food_spawner.kind.second,
				max = 0
			},
			third = {
				to = food_spawner.kind.third,
				max = 0
			}
		},
		on_food_eaten = function(food)
			snake.grow()
			food_spawner.spawn(rnd_weighted(food_spawner.kind.first.types))
		end,
		on_snake_died = function()
			sfx(1)
		end
	},
	[lv_normal] = {
		food_kind = {
			first = {
				to = food_spawner.kind.first,
				max = 0,
				types = {
					{ to = ordinary_food, weight = w3 },
					{ to = score_food, weight = w1 }
				}
			},
			second = {
				to = food_spawner.kind.second,
				max = 0,
				types = {

				}
			},
			third = {
				to = food_spawner.kind.third,
				max = 0,
				types = {
					
				}
			}
		}
	},
	[lv_hard] = {
		food_kind = {
			first = {
				to = food_spawner.kind.first,
				max = 0,
				types = {
					{ to = ordinary_food, weight = w1 },
					{ to = score_food, weight = w0 }
				}
			},
			second = {
				to = food_spawner.kind.second,
				max = 0,
				types = {

				}
			},
			third = {
				to = food_spawner.kind.third,
				max = 0,
				types = {
					
				}
			}
		}
	},
	load = function(cur_level)
		for _, kind in pairs(cur_level.food_kind) do
			kind.to.max = kind.max
			if kind.max ~= 0 then
				foreach(
					kind.types,
					function(type)
						if type ~= nil then
							type.to.weight = type.weight
						end
					end
				)
			end
		end
	end
}
-- 

--------------------
-- init function --
--------------------
function _init()
	init()
	snake.init()
	food_spawner.init()
end

--------------------
-- update function --
--------------------
function _update()
	if tick then
		frame = (frame + 1) % fps
	end
	snake.update()
	foreach(
		foods,
		function(food)
			food.type.update(food)
		end
	)
end

--------------------
-- draw function --
--------------------
function _draw()
	cls(c05)
	foreach(
		foods,
		function(food)
			food.type.draw(food)
		end
	)
	snake.draw()
	print("score: "..score, 1, 1, c09)

	-- 
	if debug then
		print("debug "..bug, 1, 122, c08)
	end
end

-- game manager
-- 
function init()
	load_level(lv_peaceful)
end

function load_level(cur)
	cur_lv = cur
	level.load(level[cur_lv])
end
-- 

-- tool function
-- 
function shallow_copy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function deep_copy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deep_copy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function is_empty(t)
	return next(t) == nil
end

function size(t)
	local cnt = 0
	for _, _ in pairs(t) do
		cnt += 1
	end
	return cnt
end

function rnd_equal(t)
	local vals = {}
	for _, v in pairs(t) do
		add(vals, v)
	end
	return vals[flr(rnd(#vals)) + 1]
end

function rnd_weighted(t)
	local total = 0
	for _, v in ipairs(t) do
		total += v.weight
	end
	local r = flr(rnd(total))
	total = 0
	for _, v in ipairs(t) do
		total += v.weight
		if total > r then
			return v
		end
	end
end

function has(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true
		end
	end
	return false
end

-- 

function coordinate_copy(from, to)
	to.x = from.x
	to.y = from.y
end

function to_tile(v)
	return v * 8
end

function overlap(point_a, point_b)
	return point_a.x == point_b.x and point_a.y == point_b.y
end

function is_snake_at(point)
	local is = false
	foreach(
		snake.parts,
		function(part)
			if overlap(part, point) then
				is = true
			end
		end
	)
	return is
end

function is_food_at(point)
	local is = false
	foreach(
		foods,
		function(food)
			if overlap(food, point) then
				is = true
			end
		end
	)
	return is
end

function loop(point)
	if point.x < 0 then
		point.x = scn_len - 1
	elseif point.x > scn_len - 1 then
		point.x = 0
	end
	if point.y < 0 then
		point.y = scn_len - 1
	elseif point.y > scn_len - 1 then
		point.y = 0
	end
end
-- 
