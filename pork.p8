pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--main
function _init()
	mobs_ani={
		240,
		192
	}
	mobs_hp={5,2}
	mobs_atk={1,1}
	
	t=0
	p_ani={240,241,242,243}
	_upd=update_game
	_drw=draw_game
	dir_x={-1,1,0,0,1,1,-1,-1}
	dir_y={0,0,-1,1,-1,1,1,-1}
	start_game()
	
	debug={}
end

function _update60()
	t+=1
	_upd()
	do_floats()
end

function _draw()
	_drw()
	draw_winds()
	
	cursor(4,4)
	color(8)
	for txt in all(debug) do
		print(txt)
	end
end

function start_game()
	button_buffer=-1
	
	mobs={}
	p_mob=add_mob(1,4,5)
	for x=0,15 do
		for y=0,15 do
			if mget(x,y)==192 then
				add_mob(2,x,y)
				mset(x,y,1)
			end
		end
	end
	p_t=0
	winds={}
	talk_wnd=nil
	floats={}
end
-->8
--update
function update_game()
	if talk_wnd then
		if get_button()==5 then
			talk_wnd.dur=0
			talk_wnd=nil
		end
	else
		do_buffer_button()
		do_button(button_buffer)
		button_buffer=-1
	end
end

function update_pturn()
	do_buffer_button()
	p_t=min(p_t+0.125,1)
	
	p_mob.mov(p_mob,p_t)
	
	if p_t==1 then
		_upd=update_game
--after player moved,move mobs
		do_ai()
	end
end

function update_ai_turn()
	p_t=min(p_t+0.125,1)
	
	for m in all(mobs) do
		if m.mov then
			m.mov(m,p_t)
		end
	end
	
	if p_t==1 then
		_upd=update_game
	end
end

function update_gameover()
end

function do_buffer_button()
	if button_buffer==-1 then
		button_buffer=get_button()
	end
end

function get_button()
	for i=0,5 do
		if btnp(i) then
			return i
		end
	end
	return -1
end

function do_button(button)
	if button<0 then return end
	if button<4 then
		move_player(dir_x[button+1],dir_y[button+1])
	end
	--other buttons
end
-->8
--draws
function draw_game()
	cls(0)
	map()
--	drawspr(getframe(p_ani),p_x*8+p_ox,p_y*8+p_oy,10,p_flip)
	for m in all(mobs) do
		local col=10
		if m.flash>0 then
			m.flash-=1
			col=7
		end
		draw_spr(get_frame(m.ani),m.x*8+m.ox,m.y*8+m.oy,col,m.flp)
	end
	
	for f in all(floats) do
		oprint8(f.txt,f.x,f.y,f.c,0)
	end
end

function draw_gameover()
end
-->8
--tools
function get_frame(ani)
	return ani[flr(t/8)%#ani+1]
end

function draw_spr(_spr,_x,_y,_c,_flip)
	palt(0, false)
	pal(6,_c)
	spr(_spr,_x,_y,1,1,_flip)
	pal()
end

function rectfill2(_x,_y,_w,_h,_c)
	rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end

function oprint8(_t,_x,_y,_c,_c2)
	for i=1,8 do
		print(_t,_x+dir_x[i],_y+dir_y[i],_c2)
	end
	print(_t,_x,_y,_c)
end

function dist(fx,fy,tx,ty)
	local dx,dy=fx-tx,fy-ty
	return sqrt(dx*dx+dy*dy)
end
-->8
--gameplay

function move_player(dx,dy)
	local dest_x,dest_y=p_mob.x+dx,p_mob.y+dy
	local tle=mget(dest_x,dest_y)
	
	if is_walkable(dest_x,dest_y,"checkmobs") then
		sfx(63)
		mob_walk(p_mob,dx,dy)
		p_t=0
		_upd=update_pturn
	else
			--solid
		mob_bump(p_mob,dx,dy)
		p_t=0
		_upd=update_pturn
		
		local mob=get_mob(dest_x,dest_y)
		if not mob then
			if fget(tle,1) then
				--obstacle
				trig_bump(tle,dest_x,dest_y)
			end
		else
			--mob
			sfx(58)
			hit_mob(p_mob,mob)
		end
	end
end

function trig_bump(tle,dest_x,dest_y)
	if tle==7 or tle==8 then
		--vase
		sfx(59)
		mset(dest_x,dest_y,1)
	elseif tle==10 or tle==12 then
		--chest
		sfx(61)
		mset(dest_x,dest_y,tle-1)
	elseif tle==13 then
		--door
		sfx(62)
		mset(dest_x,dest_y,1)
	elseif tle==6 then
		--sign
		sfx(62)
--		showmsg("hello world",120)
		if dest_x==5 and dest_y==3 then
			show_msg({"welcome to porklike","","climb the tower","to obtain the","golden kielbasa"})
		elseif dest_x==9 and dest_y==4 then
			show_msg({"you're almost there..."})
		end
	end
end

function get_mob(x,y)
	for m in all(mobs) do
		if m.x==x and m.y==y then
			return m
		end
	end
end

function is_walkable(x,y,mode)
	if mode==nil then mode="" end
	if in_bounds(x,y) and not fget(mget(x,y),0) then
		if mode=="checkmobs" then
			return not get_mob(x,y)
		end
		return true
	end
end

function in_bounds(x,y)
	return not (x<0 or y<0 or x>15 or y>15)
end

function hit_mob(atk,def)
	local dmg=atk.atk
	def.hp-=dmg
	def.flash=10
	add_float("-"..dmg,def.x*8,def.y*8,9)
	if def.hp<=0 then
		del(mobs,def)
	end
end
-->8
--ui

function add_wind(_x,_y,_w,_h,_txt)
	local wind={x=_x,
												y=_y,
												w=_w,
												h=_h,
												txt=_txt}
	add(winds,wind)
	return wind
end

function draw_winds()
	for w in all(winds) do
		local wx,wy,ww,wh=w.x,w.y,w.w,w.h
		rectfill2(wx,wy,ww,wh,0)
		rect(wx+1,wy+1,wx+ww-2,wy+wh-2,6)
		wx+=4
		wy+=4
		
		clip(wx,wy,ww-8,wh-8)
		
		for i=1,#w.txt do
			local txt=w.txt[i]
			print(txt,wx,wy,6)
			wy+=6
		end
		
		clip()
		if w.dur!=nil then
			w.dur-=1
			if w.dur<=0 then
				local dif=w.h/4
				w.h-=dif
				w.y+=dif/2
				if w.h<3 then
					del(winds,w)
				end
			end
		else
			oprint8("❎",wx+ww-15,wy+1+min(sin(time(0)*3)),6,0)
		end
	end
end

function show_msg(txt,dur)
	local wid=(#txt+2)*4+7
	local w=add_wind(63-wid/2,50,wid,13,{" "..txt})
	w.dur=dur
end

function show_msg(txt)
	talk_wnd=add_wind(16,50,94,#txt*6+7,txt)
	talk_wnd.button=true
end

function add_float(_txt,_x,_y,_c)
	add(floats, {
		txt=_txt,
		x=_x,
		y=_y,
		c=_c,
		target_y=_y-10,
		timer=0
	})
end

function do_floats()
	for f in all(floats) do
		f.y+=(f.target_y-f.y)/10
		f.timer+=1
		if f.timer>70 then
			del(floats,f)
		end
	end
end
-->8
--mobs

function add_mob(typ,mx,my)
	local m={
		x=mx,
		y=my,
		ox=0, --ofset(destination)
		oy=0,
		sox=0, --starting offset
		soy=0,
		flp=false,
		mov=nil,
		ani={},
		flash=0,
		hpmax=mobs_hp[typ],
		hp=mobs_hp[typ],
		atk=mobs_atk[typ]
	}
	
--fill animation
	for i=0,3 do
		add(m.ani,mobs_ani[typ]+i)
	end
	
	add(mobs,m)
	
	return m
end

function mob_walk(m,dx,dy)
	mob_flip(m,dx)
	m.x+=dx
	m.y+=dy
	m.sox,m.soy=-dx*8,-dy*8
	m.ox,m.oy=m.sox,m.soy
	m.mov=mov_walk
end

function mob_bump(m,dx,dy)
	mob_flip(m,dx)
	m.sox,m.soy=dx*8,dy*8
	m.ox,m.oy=0,0
	m.mov=mov_bump
end

function mob_flip(m,dx)
	if dx<0 then 
		m.flp=true
	elseif dx>0 then 
		m.flp=false
	end
end

function mov_walk(mob,ani_t)
	mob.ox=mob.sox*(1-ani_t)
	mob.oy=mob.soy*(1-ani_t)
end

function mov_bump(mob,ani_t)
	local tme=ani_t
	if ani_t>0.5 then
		tme=1-ani_t
	end
	mob.ox=mob.sox*tme
	mob.oy=mob.soy*tme
end

function do_ai()
	for m in all(mobs) do
		if m != p_mob then
			m.mov=nil
			if dist(m.x,m.y,p_mob.x,p_mob.y)==1 then
				--attack player
				dx,dy=p_mob.x-m.x,p_mob.y-m.y
				mob_bump(m,dx,dy)
				hit_mob(m,p_mob)
				sfx(57)
			else
				--move towards player
				--b for best
				local b_dst,b_x,b_y=999,0,0
				for i=1,4 do
					local dx,dy=dir_x[i],dir_y[i]
					local tx,ty=m.x+dx,m.y+dy
					if is_walkable(tx,ty,"checkmobs") then
						local dst=dist(tx,ty,p_mob.x,p_mob.y)
						if dst<b_dst then
							b_dst,b_x,b_y=dst,dx,dy
						end
					end
				end
				mob_walk(m,b_x,b_y)
			end
			_upd=update_ai_turn
		end
	end
end
__gfx__
000000000000000060666060000000000000000000000000aaaaaaaa00aaa00000aaa00000000000000000000000000000aaa000a0aaa0a0a000000055555550
000000000000000000000000000000000000000000000000aaaaaaaa0a000a000a000a00066666600aaaaaa06666666000aaa00000000000a0aa000000000000
007007000000000066606660000000000000000000000000a000000a0a000a000a000a00060000600a0000a060000060a00000a0a0aaa0a0a0aa0aa055000000
00077000000000000000000000000000000000000000000000aa0a0000aaa000a0aaa0a0060000600a0aa0a060000060a00a00a000aaa00000aa0aa055055000
000770000000000060666060000000000000000000000000a000000a0a00aa00aa00aaa0066666600aaaaaa066666660aaa0aaa0a0aaa0a0a0000aa055055050
007007000005000000000000000000000000000000000000a0a0aa0a0aaaaa000aaaaa000000000000000000000000000000000000aaa000a0aa000055055050
000000000000000066606660000000000000000000000000a000000a00aaa00000aaa000066666600aaaaaa066666660aaaaaaa0a0aaa0a0a0aa0aa055055050
000000000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000060666000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06066600060666000606660006666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666660066666006066666060066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660066666006666666066666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600006660000666660006666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000606000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060600006666000006060000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600000606660066660000060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060666000666660006066600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06066666006000000006666606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66000000066066000660000066066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66066606066066000660660066066606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600000660000060060000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010000000303030103010303020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202010101010101010101010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201c00202020202020202020202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201020202060c0a070702020202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02c0010201010101080602020202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020201020f020202010801080202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101c0010102c0020d0201020202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202010202020202010201020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020101c0c0c0010101020c0202010e0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020202020102020a0201020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202010202020201010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202010101010101020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202010202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002012020120161202712009610096101a6100c600186101a200176101a2000e61008200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000018630085301862017620126200f6200b62008610056100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000255302a5302d5302d53000000000000000026510265102651028510000000000000000255102751027510000000000000000000002251022510225102551027510000000000000000000000000000000
000100002602026020150201502026220202201d2101921015210122100d2100a2100821004210042100421004210042100421004210042100421003210032100321003210032100321003210032100000000000
000100001f0201f02019020180203402036020370202c0102c0102c01020010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002503027030230402303014030130100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000e720147200e7100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
