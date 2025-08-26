pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
  spr_size=8
  screen_size=128
  fancyfill_ct=1
  fancyfill={
    0b1010010101011010,
    0b0101010110101010,
    0b0101101010100101,
    0b1010101001010101,
  }

  -- helper to make color names readable
  colors={black=0,blue_d=1,purp_d=2,green_d=3,brown=4,grey_d=5,grey_l=6,white=7,red=8,orange=9,yellow=10,green_l=11,blue=12,lavender=13,pink=14,peach=15}
  pi=3.1415

  -- init_scroller({5,5,6,7,5,22,23},23)
  init_scroller({5,7},23)

  player={
    health=5,
    stats={str=03,dex=03,luk=01,},
    stats_order={"str","dex","luk"},
    get_hearts=function(self)
      if self.health==0 then return {7,7,7,7} end
      if self.health==1 then return {6,7,7,7} end
      if self.health==2 then return {5,7,7,7} end
      if self.health==3 then return {5,6,7,7} end
      if self.health==4 then return {5,5,7,7} end
      if self.health==5 then return {5,5,6,7} end
      if self.health==6 then return {5,5,5,7} end
      if self.health==7 then return {5,5,5,6} end
      if self.health==8 then return {5,5,5,5} end
    end,
  }
  
  -- [m]ap, [s]hop, [e]ncounter
  states={m=0,s=1,e=2}
  gamestate=states.e

  frame_ct=0
end

--[[
  .-----------------------.
  |32768|16384| 8192| 4096|  xoxo xoxo oxox oxox
  |-----|-----|-----|-----|  xoxo oxox oxox xoxo
  | 2048| 1024| 512 | 256 |  oxox oxox xoxo xoxo 
  |-----|-----|-----|-----|  oxox xoxo xoxo oxox
  | 128 |  64 |  32 |  16 |
  |-----|-----|-----|-----|
  |  8  |  4  |  2  |  1  |
  '-----------------------'
]]

-->8
function _update()
  frame_ct+=1

  -- shift bg fill every 2 frames
  if frame_ct%2==0 then
    fancyfill_ct+=1
  end

  update_scroller()
end

-->8
function _draw()
  -- bg draw
  cls(0)                              -- clear screen black
  set_fill("ff")                      -- set fancy upward scrolling fill
  rectfill(0,0,128,128,colors.blue_d) -- draw fill across entire screen
  set_fill()                          -- reset to solid fill

  -- map gamestate
  if gamestate==states.m then
    --continue

  -- encounter gamestate
  elseif gamestate==states.e then
    draw_encounter()

  -- shop encounter 
  elseif gamestate==states.s then
    --continue

  else 
    -- throw
    error("gamestate ".." not accounted for") 
  end

  -- draw the persistent ui on top of everything else
  draw_sidebar()
end

-- render the sidebar on the screen
function draw_sidebar()
  map()

  -- health ----------------
  fancy_container(1,10,25,26,3,colors.blue_d,colors.white)
  hearts=player:get_hearts()
  spr(hearts[1], 4,  14)
  spr(hearts[2], 15, 14)
  spr(hearts[3], 4,  24)
  spr(hearts[4], 15, 24)
  
  -- stats -----------------
  draw_stats()

  -- items -----------------
  fancy_container(1,92,25,26,3,colors.blue_d,colors.white)
  spr(53, 4, 96)
  spr(8, 15, 96)
  spr(8, 4, 106)
  spr(8, 15, 106)
end

function draw_encounter()
  map_start,map_end=32,128
  map_width=map_end-map_start
  map_center=map_start+(map_width/2)

  -- draw_icon_at(22,map_center-16-4,100,false,true) -- 16=box width, 4=gap
  -- draw_icon_at(23,map_center,     100,true,false)
  -- draw_icon_at(25,map_center+16+4,100,false,true)
  -- rrectfill_c(map_center-1, 128-47, map_width-4, 11*8, 7, colors.lavender)
  rrectfill_c(map_center-1, 128/2, map_width-4, 128-6, 7, colors.lavender)
  rrect_c(map_center-1, 128/2, map_width-4, 128-6, 7, colors.white)
  
  draw_scroller()
end

-- Initialize the random choice scroller required fields
function init_scroller(sprs, y)
  --[[
    args: 
      sprs: table of sprite IDs to render on the scroller
      y:    y-position to draw the scroller at
      spd:  initial speed to start the items scrolling at
      gap:  spacing between each of the in the scroller
      drag: drag coefficient to slow the scroll by
  ]]

  -- shuffle order of sprites
  shuffle_inplace(sprs)

  -- insert items into table based on a pseudo-random speed + drag coeffecient
  -- choices below are intentionally chosen so the scroll wheel lands approximately
  -- in the center of the item box every time
  -- TODO: refactory to save a few tokens
  local possible_scrollers={
    {sprs={},y=y,spd=7,gap=10,drag=0.0602,spr_w=8,items={}},
    {sprs={},y=y,spd=9,gap=10,drag=0.070555,spr_w=8,items={}},
    {sprs={},y=y,spd=8,gap=10,drag=0.0777011,spr_w=8,items={}},
    {sprs={},y=y,spd=8,gap=10,drag=0.072,spr_w=8,items={}},
    {sprs={},y=y,spd=6,gap=10,drag=0.0645,spr_w=8,items={}},
  }
  scroll_data=possible_scrollers[flr(rnd(#possible_scrollers))+1]
  local s = scroll_data

  -- reinsert the table data (maintaining the shuffled order) until at least 8 items are included
  while #s.sprs < 8 do 
    for i=1,#sprs do 
      add(s.sprs, sprs[i]) 
    end
  end

  -- set up item data + table metadata
  local step = 8 + s.gap
  for i=1,#s.sprs do 
    scroll_data.items[i] = {
      x=-(i-1)*step,
      selected=false,
    }
  end
  scroll_data.total_width = (#scroll_data.sprs) * step
end

-- update positions of items on the scroller and apply drag every game tick
function update_scroller()
  local s = scroll_data
  if not s then return end
  s.spd = max(0, s.spd - s.drag)
  for i=1,#s.sprs do
    -- move based on spd
    s.items[i].x += s.spd

    -- wrap when fully outside of screen
    if s.items[i].x > 128 + s.spr_w then
      s.items[i].x -= s.total_width
    end
    
    -- set if the item is selected or not
    if abs((29+128)/2 - s.items[i].x) < 9 then 
      s.items[i].selected = true
    else
      s.items[i].selected = false 
    end
  end
end

-- draw sprites at their positions; call from _draw()
function draw_scroller(id)
  -- todo: refactor away some of these unused tokens
  -- draw the main container box w a 1px dropshadow
  local banner_top, banner_bottom, banner_left = scroll_data.y-11, scroll_data.y+10, 28
  local banner_center_h, banner_center_v = (banner_left+128)/2 , (banner_bottom+banner_top)/2 + 1
  rrectfill_c(banner_center_h, banner_center_v, 2+128-banner_left, 23, 0, colors.blue_d)
  rrect_c(banner_center_h, banner_center_v, 2+128-banner_left, 22, 0, colors.white)
  
  -- draw the line marking the center of the
  rrectfill_c(banner_center_h, banner_center_v+1, 4, 28, 0, colors.blue_d)
  rrectfill_c(banner_center_h, banner_center_v+1, 2, 26, 0, colors.white)

  -- draw items
  for i=1,#scroll_data.sprs do
    draw_icon_at(
      scroll_data.sprs[i], 
      flr(scroll_data.items[i].x), 
      scroll_data.y, 
      scroll_data.items[i].selected, 
      true
    )
  end
end


-- draw a given sprite to the game map
function draw_icon_at(s,x,y,se,dd)
  --[[
    args: 
      s:  sprite to draw
      x:  x position
      y:  y position
      se: selected? (optional, bool)
      dd: disable dropshadow (optional, bool)
  ]]

  if se then 
    fancy_container_c(x,y,16,16,3,colors.lavender,colors.white,"fr",dd)
    point_indicator_at(x,y-10,10,30)
    spr_outline_c(s,x,y,colors.white)
  else 
    fancy_container_c(x,y,16,16,3,colors.blue_d,colors.lavender,"fs",dd)
    spr_c(s,x,y,8,8)
  end
end

-- draw a moving pointer indicated over a position by a specific offset
function point_indicator_at(x,y,o,fpc)
  --[[
    args:
      x:   x position
      y:   y position
      o:   offset amount
      fpc: frames per cycle (e.g. 30 -> one full full up/down cycle every 30 frames)
  ]]
  local wiggle = flr(sin(frame_ct/fpc)+0.5)
  spr(21, x-4, y-o+wiggle)
end

function fancy_container(x,y,w,h,r,f,b,ft,dd)
  --[[
    Draw a fancy UI container to the screen

    Args: 
      x:  Starting x position
      y:  Starting y position
      w:  Width of the container
      h:  Height of the container
      r:  Border radius
      f:  Fill color
      b:  Border color
      ft: Fill type --  "fr" (default) | "ff" | "fs" -- see set_fill() for details
      dd: Disable dropshadow
  ]]
  if (ft == nil) ft = "fr"
  set_fill()                                  -- solid fill
  rrectfill(x, y, w, h, r, f)                 -- fill solid
  set_fill(ft)                                -- fancy fill (inv.)
  rrectfill(x, y, w, h, r, f)                 -- populate rect w fancy fill
  set_fill()                                  -- solid fill
  if not dd then rrect(x, y+1, w, h, r, 1) end  -- border drop shadow (optional)
  rrect(x, y, w, h, r, b)                     -- border
end

-- Set fill type based on passed type (t)
function set_fill(t)
  --[[
    args:
      nil:  solid fill
      "ff": fancy-fill (upward scrolling)
      "fr": fancy-fill reversed (downward scrolling)
      "fs": fancy-fill static
  ]]
  if     t==nil  then fillp()
  elseif t=="ff" then fillp(fancyfill[(fancyfill_ct%4)+1])
  elseif t=="fr" then fillp(fancyfill[((fancyfill_ct*-1)%4)+1])
  elseif t=="fs" then fillp(fancyfill[1])
  else error("Fill type not accounted for") end
end

-- draw the current player stats to the sidebar
function draw_stats()
  local base_height,spacing,line_gap=45,12,7
  for i=1,#player.stats_order do
    local k = player.stats_order[i]
    local v = player.stats[k]
    local val = v < 10 and "0"..v or v
    local base_y = base_height + (spacing * (i-1))
    print(k..":"..val, 2, base_y+1, 1)                   -- draw text
    print(k..":"..val, 2, base_y, 7)                     -- draw text drop shadow
    line(2, base_y+line_gap,   24, base_y+line_gap,   7) -- draw underline
    line(2, base_y+line_gap+1, 24, base_y+line_gap+1, 1) -- draw underline shadow
  end
end

-- Helper functions for centering
function rect_c(x,y,w,h,c)
  --[[
    draw a rect centered about a point

    args:
      x: target x position
      y: target y position
      w: width
      h: height
      c: color
  ]]
  rect(x-(w/2), y-(h/2),w,h,c)
end

function rrect_c(x,y,w,h,r,c)
  --[[
    draw a rounded rect centered about a point
    
    args:
      x: target x position
      y: target y position
      w: width
      h: height
      r: radius
      c: color
  ]]
  rrect(x-(w/2), y-(h/2),w,h,r,c)
end

-- centered variant of rrectfill
function rrectfill_c(x,y,w,h,r,c)
  rrectfill(x-(w/2), y-(h/2),w,h,r,c)
end

-- centered variant of normal fancy container
function fancy_container_c(x,y,w,h,r,f,b,ft,dd)
  fancy_container(x-(w/2), y-(h/2),w,h,r,f,b,ft,dd)
end

-- centered variant of a spr function
function spr_c(n,x,y,w,h,fx,fy)
  --[[
    Args:
      n: sprite id to draw
      x: x position
      y: y position
      w: width
      h: height
      fx: flip x (bool)
      fy: flip y (bool)
  ]]
  spr(n,x-(w/2),y-(h/2))
end

-- helper outline fxn lifted from achie72 on github then minified for token: 
-- https://gist.github.com/Achie72/a249edb0e1c32cdaedf721726f2d8d34
function spr_outline(s, x, y, c, th, xs, ys, fh, fv)
  --[[
    draw a sprite at a position with a given color + thickness

    args:
      s:  target sprite
      x:  x position
      y:  y position
      c:  color
      th: outline thickness
      xs: x_size
      ys: y_size
      fh: flip horizontal flag
      fv: flip vertical flag
  ]]
  if (c == nil) c = 7
  if (th == nil) th = 1 
  if (xs == nil) xs = 1    
  if (ys == nil) ys = 1 
  
  for i=1,15,1 do pal(i, c) end
  if c == 0 then palt(0, false) end
  for i=-th,th do for j=-th,th do spr(s, x-i, y-j, xs, ys, fh, fv) end end
  if c == 0 then palt(0, true) end
  pal()
  spr(s, x, y, xs, ys, fh, fv)
end


-- centered variant of spr_outline function
function spr_outline_c(s, x, y, c, th, xs, ys, fh, fv)
  spr_outline(s, x-4, y-4, c, th, xs, ys, fh, fv)
end

-- shuffle a table's items in-place
function shuffle_inplace(t)
  --[[
    args: 
      t: table to shuffle
  ]]
  for i=#t,2,-1 do
    local j = flr(rnd(i)) + 1
    t[i], t[j] = t[j], t[i]
  end
  return t
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000dd00dd00dd00dd00dd00dd000d55d0000d67700080880800000000000000000000000000000000000000000
0070070000000000000000000000000000000000de7dde7dde7dd55dd55dd55d0d5115d006d66670082882800000000000000000000000000000000000000000
00077000000007aa7a999aa77a99aaaaaa900000e887e887e887511551155115051111500d616160028888200000000000000000000000000000000000000000
0007700000007a99999449999449999949aa0000e888888ee888111551111115051111500d616160028888200000000000000000000000000000000000000000
007007000007a9111111111111111111194a9000de8888edde88115dd511115d0d5115d000676760012882100000000000000000000000000000000000000000
000000000004941dddddddddddddddddd114a0000de88ed00de815d00d5115d000d55d0000616160001221000000000000000000000000000000000000000000
000000000009a1ddddddddddddddddddddd1a00000deed0000de5d0000d55d000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddda00000aaaa00e0a0a0ae29999000566660000d6666d0006666000000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddd90000a9009a0e8aa7a7e2224000005dd0000d66dd66d066666600000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddda000090000a0666dd666049999900d666660d6d00d66666666660000000000000000000000000000000000000000
000000000004dddd00000000dddddddddddda000090000a066666666499aaa99d66ccc660000d66d666666660000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddda00009a00a90d116611d49a999a9d6c666c6000d66d0d61661660000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddd9000009aa90066666666499aaa99d66ccc6600d66d00d616616d0000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddda000009aa900d66ee66d249999945d66666d000000000dddddd00000000000000000000000000000000000000000
000000000009dddd00000000dddddddddddda000000990000dd22dd00244442005dddd5000d66d00000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddd90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddd40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000adddd0000000000000000dddda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000004dddd0000000000000000dddd90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddd90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009dddd0000000000000000dddda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e00000020009addddddddddddddddddddddda0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e000020000497ddddddddddddddddddddda90000666677004444990000000000000000000000000000000000000000000000000000000000000000000000000
00e0020000049adddddddddddddddddddaa9900067dd5d7749225299000000000000000000000000000000000000000000000000000000000000000000000000
000e2000000049a7aaa77a7aaa7aa7aaa99400007500005795000059000000000000000000000000000000000000000000000000000000000000000000000000
0002e000000009999449999499994999944000006700006d49000042000000000000000000000000000000000000000000000000000000000000000000000000
00200e0000000000000000000000000000000000d676677d24944992000000000000000000000000000000000000000000000000000000000000000000000000
020000e00000000000000000000000000000000005d55dd005255220000000000000000000000000000000000000000000000000000000000000000000000000
2000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0302020400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313132400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3232323400000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
