-- const
-- 
-- keys
key_left = 0
key_right = 1
key_up = 2
key_down = 3
key_jump = 4
key_dash = 5

-- directions
dir_left = { x = -1, y = 0 }
dir_right = { x = 1, y = 0 }
dir_up = { x = 0, y = -1 }
dir_down = { x = 0, y = 1 }

-- other
fps = 30
length = 16

-- global variables
tick = true
frame = 0
score = 0
foods = {}

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
	head = { x = 4, y = 4, front = { x = 0, y = 0 }, spr = 1 },
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
			snake.tail.spr = 2
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
		sfx(1)
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
		snake.dead_part.spr = 5
		if snake.dead_part.prev == nil then
			snake.dead_part.spr = 4
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


		-- for debug
		if btnp(key_dash) then
			snake.grow()
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

-- food
-- 
function spawn_food()
	local food = {}
	while true do
		food.x = flr(rnd(length))
		food.y = flr(rnd(length))
		if not is_in_snake(food) then
			break
		end
	end
	food.spr = 3
	food.eaten = function()
		sfx(0)
		snake.grow()
		score += 1
		del(foods, food)
	end
	food.update = function()
		if overlap(food, snake.head) then
			spawn_food()
			food.eaten()
		end
	end
	food.draw = function()
		spr(food.spr, to_tile(food.x), to_tile(food.y))
	end
	add(foods, food)
end

-- init function
function _init()
	snake.init()
	spawn_food()
end

-- update function
function _update()
	if tick then
		frame = (frame + 1) % fps
	end
	snake.update()
	foreach(
		foods,
		function(food)
			food.update()
		end
	)
end

-- draw function
function _draw()
	cls(5)
	foreach(
		foods,
		function(food)
			food.draw()
		end
	)
	snake.draw()
	print("score: "..score, 1, 1, 9)
end

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

function coordinate_copy(from, to)
	to.x = from.x
	to.y = from.y
end

function is_empty(t)
	return next(t) == nil
end

function to_tile(v)
	return v * 8
end

function overlap(point_a, point_b)
	return point_a.x == point_b.x and point_a.y == point_b.y
end

function is_in_snake(point)
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

function loop(point)
	if point.x < 0 then
		point.x = length - 1
	elseif point.x > length - 1 then
		point.x = 0
	end
	if point.y < 0 then
		point.y = length - 1
	elseif point.y > length - 1 then
		point.y = 0
	end
end
