--Breakout game cloned from LazyDevs

--初始化函数
function _init()
    --盗版检测
    pirate=false
    if(stat(l02)!="www.lexaloffle.com" and stat(102)!=0) pirate=true
    cartdata("lazydevs_hero1_v2")
    cls()

    screenbox={
        left=126,
        right=1,
        top=140,
        bottom=7
    }

    mode="logo"
    lcnt=0
    level=""
    debug=""
    levelnum=1
    levels={}
    loadlevels()
    startlives=4
    fastmode=false
    sd_brick=nil
    sd_timer=0
    sd_thresh=1
    shake=0

    brick_g=7
    brick_g_i=1
    brick_w=7
    brick_w_i=1
    brick_b=7
    brick_b_i=1
    brick_r=7
    brick_r_i=1

    blinkframe=0
    blinkspeed=8

    fadeperc=1

    startcountdown=-1
    govercountdown=-1
    goverrestart=false
    arrm=1
    arrm2=1
    arrmframe=0

    --particles
    part={}
    lasthitx=0
    lasthity=0

    --speedline windup
    spdwind=0

    --highscore
    hs={}
    hst={}
    hs1={}
    hs2={}
    hs3={}
    hsb={true,false,false,false,false}

    --reseths()
    loadhs()

    hschars={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
    hs_x=128
    hs_y=128
    loghs=false

    --typing in intitails
    nitials={1,1,1}
    nit_sel=1

    --sash
    sash_w=0
    sash_dw=0
    sash_tx=0
    sash_tdx=0
    sash_c=8
    sash_tc=7
    sash_text="ohai"
    sash_frames=0
    sash_v=false
    sash_delay_w=0
    sash_delay_t=0

    --particle partterns
    parttimer=0
    partrow=0
    startparts()

    --infinite loop protection
    infcounter=0

    --sick messages
    sick={
        "so sick!",
        "yeee boiii!",
        "impressive!",
        "i can't even...",
        "it's lit!",
        "mah dude!",
        "c-c-combo!",
        "winning!",
        "niiiice",
        "worh",
        "seriously now?",
        "maximum pwnage!"
    }

    --music
    music(1)
end


function startgame()
    levelnum=1
    level=levels[levelnum]
    restartlevel()
end


function restartlevel()
    mode="game"
    
    --ball
    ball_r=2
    ball_dr=0.5
    ball_spd=1
    if(fastmode) ball_spd=1.5

    --paddle
    pad_x=64
    pad_y=120
    pad_dx=0
    pad_wo=24
    pad_w=24
    pad_h=6
    pad_c=7

    --bricks
    brick_w=9
    brick_h=4
    buildbricks(level)
    
    --inital
    lives=startlives
    points=0
    points2=0
    sticky=false
    chain=1

    --timer for powerups
    timer_mega=0
    timer_mega_w=0
    timer_slow=0
    timer_expand=0
    timer_reduce=0

    --sash
    showsash("stage "..levelnum,0,7)
    serveball()
end


function nextlevel()
    mode="game"
    pad_x=52
    pad_y=120
    pad_dx=0

    levelnum+=1
    if levelnum > #levels then
        wingame()
        return
    end
    level=levels[levelnum]
    buildbricks(level)

    chain=1
    sticky=false
    timer_mega=0
    timer_mega_w=0
    timer_slow=0
    timer_expand=0
    timer_reduce=0

    showsash("stage "..levelnum,0,7)
    serveball()
end


--see the bricks as 1d array
function buildbricks(lvl)
    local i,j,o,chr,last
    bricks={}

    j=0
    --powerups:
    --b=normal brick
    --x=empty space
    --i=indestructable brick
    --h=hardened brick
    --s=sploding brick
    --p=powerup brick
    for i=1,#lvl do
        j+=1
        chr=sub(lvl,i,i)
        if chr=="b" or chr=="i" or chr=="h" or chr=="s" or chr=="p" then
            last=chr
            addbrick(j,chr)
        elseif chr=="x" then
            last="x"
        elseif chr=="/" then
            j=(flr((j-1)/11)+1)*11  --jump to next line
        elseif chr>="1" and chr<="9" then   
            for o=1,chr+0 do
                if last=="b" or last=="i" or last=="h" or last=="s" or last=="p" then
                    addbrick(j,last)
                elseif last=="x" then
                    --do nothing
                end
                j+=1
            end
            j-=1    --modify the i to the rigth position
        end
    end
end


function resetpills()
    pill={}
end


function addbrick(_i,_t)
    --the elements of bricks
    local _b={
        x=4+((_i-1)%11)*(brick_w+2),
        y=11+flr((_i-1)/11)*(brick_h+2),
        v=true,
        t=_t,
        fsh=0,  
        ox=0,
        oy=-(128+rnd(128)),
        dx=0,
        dy=rnd(64),
        hp=1,
    }
    --hardened blicks
    if _t=="h" then
        _b.hp=2
    end
    add(bricks,_b)
end


function levelfinished()
    if #bricks==0 then
        return true
    end

    for i=1,#bricks do  
        if(bricks[i].v==true and bricks[i].t!="i")  return false        
    end

    return true
end


function serveball()
    ball={} --support multiple balls
    ball[1]=newball()
    local mb=ball[1]
    mb.x=pad_x
    mb.y=pad_y-ball_r
    mb.dx=1
    mb.dy=-1
    mb.ang=1
    mb.stuck=true
    --combo sys
    sd_brick=nil
    pointsmult=1
    chain=1

    timer_mega=0
    timer_mega_w=0
    timer_slow=0
    timer_expand=0
    timer_reduce=0

    resetpills()

    sticky_x=0
    sticky=false
end


function newball()
    return {
        x=0,
        y=0,
        dx=0,
        dy=0,
        ang=1,
        stuck=false,
        rammed=false,
        colcount=0,
        collast=nil
    }
end


function copyball(ob)
    return {
        x=ob.x,
        y=ob.y,
        dx=ob.dx,
        dy=ob.dy,
        ang=ob.ang,
        stuck=ob.stuck,
        rammed=ob.rammed,   --just hit the blick? prevent damage twice
        colcount=ob.colcount,
        collast=ob.collast
    }
end


--set ball's angle
--prevent physical bugs
function setang(bl,ang)
    bl.ang=ang
    if ang==2 then
        bl.dx=0.5*sign(bl.dx)
        bl.dy=1.3*sign(bl.dy)
    elseif ang==0 then
        bl.dx=1.3*sign(bl.dx)
        bl.dy=0.5*sign(bl.dy)
    else
        bl.dx=1*sign(bl.dx)
        bl.dy=1*sign(bl.dy)
    end
end


function multiball()
    local ballnum=flr(rnd(#ball))+1
    local ogball=ball[ballnum]

    ball2=copyball(ogball)

    if ogball.ang==0 then
        setang(ball2,2)
    elseif ogball.ang==1 then
        setang(ogball,0)
        setang(ball2,2)
    else
        setang(ball2,0)
    end

    ball2.stuck=false
    ball[#ball+1]=ball2
end


function sign(n)
    if n<0 then
        return -1
    elseif n>0 then
        return 1
    else
        return 0
    end
end


--game state
function gameover()
    music(7)
    mode="gameoverwait"
    govercountdown=60
    blinkspeed=16
    resethsb()
end

function levelover()
    music(6)
    mode="leveloverwait"
    govercountdown=60
    blinkspeed=16
end

function wingame()
    music(8)
    mode="winnerwait"
    govercountdown=60
    blinkspeed=16

    --enough for high scores?
    if points2>hst[5] or (points2==hst[5] and points>hs[5]) then
        loghs=true
        nit_sel=1
        nit_conf=false
    else
        loghs=false
        resethsb()
    end
end


--release the balls
function releasestuck()
    for i=1,#ball do
        if ball[i].stuck then
            ball[i].x=mid(3,ball[i].x,124)  --clamp
            ball[i].stuck=false
        end
    end
end


--set angle to the balls stuck on the paddle
function pointstuck(sign)
    for i=1,#ball do
        if ball[i].stuck then
            ball[i].dx=abs(ball[i].dx)*sign
        end
    end
end


function powerupget(_p)
    if _p==1 then
        --slowdown
        timer_slow=400
        showsash("slowdown!",9,4)
    elseif _p==2 then
        --extra life
        lives+=1
        showsash("extra life!",7,6)
    elseif _p==3 then
        --catch
        --check if there are stuck balls
        hasstuck=false
        for i=1,#ball do
            if ball[i].stuck then
                hasstuck=true
            end
        end
        if hasstuck==false then
            sticky=true
        end
        showsash("sticky paddle!",11,3)
    elseif _p==4 then
        --expand
        timer_expand=600
        timer_reduce=0
        showsash("expand!",12,1)
    elseif _p==5 then
        --reduce
        timer_reduce=600
        timer_expand=0
        showsash("reduce!",0,8)
    elseif _p==6 then
        --megaball
        timer_mega_w=600
        timer_mega=0
        showsash("megaball!",8,2)
    elseif _p==7 then
        --multiball
        multiball()
        showsash("multiball",10,9)
    end
end


function hitbrick(_b,_combo)
    local fshtime=10
    if _b.t=="s" or _b==sd_brick then
        megaballsmash()
        infcounter=0
        sfx(2+chain)
        shatterbrick(_b,lasthitx,lasthity)
        _b.t=="zz"  --disppear the bricks

        if _b==sd_sd_brick then
            getpoints(10)
        else
            getpoints(1)
        end
        
        if(_combo) boostchain()
    elseif _b.t=="b" then
        megaballsmash()
        infcounter=0
        --regular brick
        sfx(2+chain)
        --spawn particles
        shatterbrick(_b,lasthitx,lasthity)
        _b.fsh=fshtime
        _b.v=false

        if _combo then
            getpoints(1)
            boostchain()
        end
    elseif _b.t=="i" then
        --invinvible brick
        sfx(10)
    elseif _b.t=="h" then
        megaballsmash()
        infcounter=0
        --hardened brick
        if timer_mega>0 then
            sfx(2+chain)
            shatterbrick(_b,lasthitx,lasthity)
            _b.fsh=fshtime
            _b.v=false
            if _combo then
                getpoints(1)
                boostchain()
            end
        else
            sfx(10)
            _b.fsh=fshtime
            --bump the brick
            _b.dx=lasthitx*0.25
            _b.dy=lasthity*0.25
            _b.hp-=1
            if _b.hp<=0 then
                _b.t="b"
            end
        end
    elseif _b.t=="p" then
        megaballsmash()
        infcounter=0
        --powerup brick
        sfx(2+chain)
        --spawn particles
        shatterbrick(_b,lasthitx,lasthity)
        _b.fsh=fshtime
        _b.v=false
        if _combo then
            getpoints(1)
            boostchain()
        end
        spawnpill(_b.x,_b.y)
    end
end


--increase chain by one
function boostchain()
    if chain==6 then
        local _si=1+flr(rnd(#sick))
        sfx(44)
        showsash(sick[_si],-1,1)
    end
    chain+=1
    chain=mid(1,chain,7)
end


--get points
function getpoints(_p)
    if(fastmode) _p=_p*2
    if timer_reduce<=0 then
        points+=_p*chain*pointsmult
    else
        points+=(_p*chain*pointsmult)*10
    end
    if points>=10000 then
        points2+=1
        points-=10000
    end
end


function megaballsmash()
    if timer_mega_w>0 then
        timer_mega_w=0
        timer_mega=120
    end
end


--spawn pills 
function spawnpill(_x,_y)
    local _t=flr(rnd(7))+1
    add(pill,{
        x=_x,
        y=_y,
        t=_t
    })
end


function checkexplosions()
    --"zz": ready to explode
    --"z": exploding....
    for i=1,#bricks do
        if bricks[i].t=="zz" and bricks[i].v then
            bricks[i].t="z"
        end
    end

    for i=1,#bricks do
        if bricks[i].t=="z" and bricks[i].v then
            explodebrick(i)
            spawnexplosion(bricks[i].x,bricks[i].y)
            if shake<0.4 then
                shake+=0.1
            end
        end
    end

    --make sure all the zz bricks to be z bricks
    for i=1,#bricks do
        if bricks[i].t=="zz" then
            bricks[i].t="z"
        end
    end
end


--explode up, down, left, right bricks
function explodebrick(_i)
    bricks[_i].v=false
    for j=1,#bricks do
        if j!=_i and bricks[j].v and abs(bricks[j].x-bricks[_i].x)<=(brick_w+2)
        and abs(bricks[j].y-bricks[_i].y)<=(brick_h+2) then
            hitbrick(bricks[j],false)
        end
    end
end


--AABB collison, rectangle collision detection
function box_box(box1_x,box1_y,box1_w,box1_h,box2_x,box2_y,box2_w,box2_h)
 if box1_y > box2_y+box2_h then return false end
 if box1_y+box1_h < box2_y then return false end
 if box1_x > box2_x+box2_w then return false end
 if box1_x+box1_w < box2_x then return false end
 return true
end


--sudden death
function check_sd()
    local c=0
    if(sd_brick!=nil) return
    for i=1,#bricks do
        if(bricks[i].v==true and bricks[i].t!="i") c+=1
        if(c>sd_thresh) return
    end
    --trigger the sudden death if rest bricks less than thresh
    if(c<=sd_thresh) trigger_sd()
end


function trigger_sd()
    for i=1,#bricks do
        if bricks[i].v==true and bricks[i].t!="i" then
            sd_brick=bricks[i]
            showsash("sudden death!",2,8)
            sd_timer=450
            sd_blinkt=sd_timer/10
            sd_brick.fsh=4
            sfx(29)
        end
    end
end


function update_sd()
    if sd_brick!=nil then
        sd_timer-=1
        if sd_timer<1 then
            sd_brick.t="zz"
            sd_brick=nil
            return
        end
        sd_blinkt-=1

        if sd_blinkt<1 then
            sd_brick.fsh=4
            sd_blinkt=sd_timer/10
            sfx(29)
        end
    end
end


--juicy stuff
function showsash(_t,_c,_tc)
    sash_w=0
    sash_dw=4
    sash_c=_c
    sash_text=_t
    sash_frames=0
    sash_v=true
    sash_tx=-#sash_text*4
    sash_tdx=64-(#sash_text*2)  --center
    sash_delay_w=0
    sash_delay_t=5
    sash_tc=_tc
end


--screen shake
function doshake()
    local shakex=16-rnd(32)
    local shakey=16-rnd(32)
    camera(shakex*shake,shakey*shake)
    shake=shake*0.95
    if shake<0.05 then
        shake=0
    end
end


--sash blinking...
function doblink()
    local g_seq={3,11,7,11}
    local w_seq={5,6,7,6}
    local b_seq={9,10,7,10,9}
    local r_seq={8,9,10,11,12}
    blinkframe+=1
    if blinkframe>blinkspeed then
        blinkframe=0
        blink_g_i+=1
        if blink_g_i>#g_seq then
            blink_g_i=1
        end
        blink_g=g_seq[blink_g_i]

        blink_w_i+=1
        if blink_w_i>#w_seq then
            blink_w_i=1
        end
        blink_w=w_seq[blink_w_i]

        blink_b_i+=1
        if blink_b_i>#b_seq then
            blink_b_i=1
        end
        blink_b=b_seq[blink_b_i]

        blink_r=r_seq[flr(#r_seq*rnd()+1)]
    end

    --trajectory preview anim
    --first dot
    arrmframe+=1
    if arrmframe>30 then
        arrmframe=0
    end
    arrm=1+(2*(arrmframe/30))

    --second dot
    local af2=arrmframe+15
    if af2>30 then
        af2=af2-30
    end
    arrm2=1+(2*(af2/30))
end


--fading
function fadepal(_perc)
    --0 means normal
    --1 is completely black
    local p=flr(mid(0,_perc,1)*100)

    local kmax,col,dpal,j,k
    dpal={
        0,1,1,2,1,13,6,4,4,9,3,13,1,13,14
    }

    for j=1,15 do
        col=j
        kmax=(p+(j*1.46))/22 --darken function
        for k=1,kmax do
            col=dpal[col]
        end
        pal(j,col,1)
    end
end


--particle stuff
function addpart(_x,_y,_dx,_dy,_type,_maxage,_col,_s)
    add(part,{
        x=_x,
        y=_y,
        dx=_dx,
        dy=_dy,
        tpe=_type,
        mage=_maxage,   --duration
        age=0,
        col=_col[1],    --color
        colarr=_col,
        rot=0,  --rotate
        rottimer=0,
        s=_s,
        os=_s
    })
end


--ball hit the paddle will raise the puft
function spawnpuft(_x,_y)
    for i=0,5 do
        local _ang=rnd()
        local _dx=sin(_ang)*1
        local _dy=cos(_ang)*1
        addpart(_x,_y,_dx,_dy,2,15+rnd(15),{7,5,5},1+rnd(2))
    end
end


function spawnpillpuft(_x,_y,_p)
    for i=0,20 do
        local _ang=rnd()
        local _dx=sin(_ang)*(1+rnd(2))
        local _dy=cos(_ang)*(1+rnd(2))
        local _mycol

        if _p==1 then
            --slowdown --orange
            _mycol={9,9,4,4,0}
        elseif _p==2 then
            --life --white
            _mycol={7,7,6,5,0}
        elseif _p==3 then
            --catch --green
            _mycol={11,11,3,3,0}
        elseif _p==4 then
            --expand --blue
            _mycol={12,12,5,5,0}
        elseif _p==5 then
            --reduce --black
            _mycol={0,0,5,5,6}
        elseif _p==6 then
            --megaball --red
            _mycol={8,8,4,2,0}
        else
            --multiball --yellow
            _mycol={10,10,9,4,0}
        end
        addpart(_x,_y,_dx,_dy,2,20+rnd(15),_mycol,1+rnd(4))
    end
end


function spawndeath(_x,_y)
    for i=0,30 do
        local _ang=rnd()
        local _dx=sin(_ang)*(2+rnd(4))
        local _dy=cos(_ang)*(2+rnd(4))
        local _mycol
        _mycol={10,10,9,4,0}
    addpart(_x,_y,_dx,_dy,2,80+rnd(15),_mycol,3+rnd(6))
    end
end


--explosion particles
function spawnexplosion(_x,_y)
    sfx(14)
    for i=0,20 do
        local _ang=rnd()
        local _dx=sin(_ang)*(rnd(4))
        local _dy=cos(_ang)*(rnd(4))
        local _mycol
        _mycol={0,0,5,5,6}
        addpart(_x,_y,_dx,_dy,2,80+rnd(15),_mycol,3+rnd(6))
    end

    for i= 0,30 do
    local _ang = rnd()
    local _dx = sin(_ang)*(1+rnd(4))
    local _dy = cos(_ang)*(1+rnd(4))
    local _mycol
    _mycol={7,10,9,8,5}
    addpart(_x,_y,_dx,_dy,2,30+rnd(15),_mycol,2+rnd(4))
    end
end

--ball trail
function spawntrail(_x,_y)
    if rnd()<0.5 then
        local _ang=rnd()
        local _ox=sin(_ang)*ball_r*0.3
        local _oy=cos(_ang)*ball_r*0.3
        addpart(_x+_ox,_y+_oy,0,0,0,15+rnd(15),{10,9},0)
    end
end


function spawnspeedline(_x,_y)
    if rnd()<0.2 then
        local _ang=rnd()
        local _ox=sin(_ang)*ball_r
        local _oy=cos(_ang)*ball_r
        addpart(_x+_ox,_y+_oy,0,0,2,60+rnd(15),{8,2,0},1+rnd(1))
    end
end


--shatter bricks effect
function shatterbrick(_b,_vx,_vy)
    --shake when smashing bricks
    if shake<0.5 then
        shake+=0.7
    end
    sfx(13)

    _b.dx=_vx*1
    _b.dy=_vy*1

    for _x=0,brick_w do
        for _y=0,brick_h do
            if rnd()<0.5 then
                local _ang=rnd()
                local _dx=sin(_ang)*rnd(2)+(_vx/2)
                local _dy=cos(_ang)*rnd(2)+(_vy/2)
                addpart(_b.x+_x,_b.y+_y,_dx,_dy,1,80,{7,6,5},0)
            end
        end
    end

    --big chunks spawn
    local chunks=1+flr(rnd(10))
    if chunks>0 then
        for i=1,chunks do
            local _ang=rnd()
            local _dx=sin(_ang)*rnd(2)+(_vx/2)
            local _dy=cos(_ang)*rnd(2)+(_vy/2)
            local _spr=16+flr(rnd(14))
            addpart(_b.x,_b.y,_dx,_dy,3,80,{_spr},0)
        end
    end
end

--particles
--type 0 --static pixel
--type 1 --gravity pixel
--type 2 --ball of smoke
--type 3 --rotating sprite
--type 4 --blue rotating sprite
--type 5 --gravity smoke
--type 6 --speedline

function updateparts()
    local _p
    for i=#part,1,-1 do
        _p=part[i]
        _p.age+=1
        if _p.age>_p.mage then
            del(part,part[i])
        elseif _p.x<-20 or _p.x>148 then
            del(part,part[i])
        elseif _p.y<-20 or _p.y>148 then
            del(part,part[i])
        else
            --change colors
            if #_p.colarr==1 then
                _p.col=_p.colarr[1]
            else 
                local _ci=_p.age/_p.mage
                _ci=1+flr(_ci*#_p.colarr)
                _p.col=_p.colarr[_ci]
            end

            --appy gravity
            if _p.tpe==1 or _p.tpe==3 then
                _p.dy+=0.05
            end
            
            --appy low gravity
            if _p.tpe==5 then
                if abs(_p.dy)<1 then
                    _p.dy+=0.01
                end
            end

            --rotate
            if _p.tpe==3 or _p.tpe==4 then
                _p.rottimer+=1
                if _p.rottimer>5 then
                    _p.rot+=1
                    if _p.rot>=4 then
                        _p.rot=0
                    end
                end
            end

            --shrink
            if _p.tpe==2 or _p.tpe==5 or _p.tpe==6 then
                local _ci=1-(_p.age/_p.mage)
                _p.s=_ci*_p.os
            end

            --friction
            if _p.tpe==2 or _p.tpe==6 then
                _p.dx=_p.dx/1.2
                _p.dy=_p.dy/1.2
            end

            --move particle
            _p.x+=_p.dx
            _p.y+=_p.dy
        end
    end
end


--big particle drawer
function drawparts()
    for i=1,#part do
        _p=part[i]
        --pixel particle
        if _p.tpe==0 or _p.tpe==1 then
            pset(_p.x,_p.y,_p.col)
        elseif _p.tpe==2 or _p.tpe==5 then
            circfill(_p.x,_p.y,_p.s,_p.col)
        elseif _p.tpe==3 or _p.tpe==4 then
            local _fx,_fy
            if _p.tpe==3 then
                if _p.rot==2 then
                    _fx=false
                    _fy=true
                elseif _p.rot==3 then
                    _fx=true
                    _fy=true
                elseif _p.rot==4 then
                    _fx=true
                    _fy=false
                else
                    _fx=false
                    _fy=false
                end
            elseif _p.tpe==4 then
                pal(7,1)
            end
            spr(_p.col,_p.x,_p.y,1,1,_fx,_fy)
            pal()
        elseif _p.tpe==6 then
            if _p.dx<0 then
                line(_p.x,_p.y,_p.x+_p.s,_p.y,_p.col)
            else
                line(_p.x-_p.s,_p.y,_p.x,_p.y,_p.col)
            end
        end
    end
end


function animatebricks()
    for i=1,#bricks do
        local _b=bricks[i]
        if _b.v or _b.fsh>0 then
            if _b.dx~=0 or _b.dy~=0 or _b.ox~=0 or _b.oy~=0 then
                _b.ox+=_b.dx
                _b.oy+=_b.dy
                
                _b.dx-=_b.ox/10
                _b.dy-=_b.oy/10

                if abs(_b.dx)>(_b.ox) then
                    _b.dx=_b.dx/1.3
                end
                if abs(_b.dy)>(_b.oy) then
                    _b.dy=_b.dy/1.3
                end

                if abs(_b.ox)<0.2 and abs(_b.dx)<0.25 then
                    _b.ox=0
                    _b.dx=0
                end
                if abs(_b.oy)<0.2 and abs(_b.dy)<0.25 then
                    _b.oy=0
                    _b.dy=0
                end
            end
        end
    end
end

function startparts()
    for i=0,300 do
        spawnbgparts(false,i)
    end
end

--falling particles effects
function spawnbgparts(_top,_t)
    if _t%30==0 then
        if partrow==0 then
            partrow=1
        else
            partrow=0
        end
        for i=0,8 do
            if _top then
                _y=-8
            else
                _y=-8+0.4*_t
            end
            if(i+partrow)%2==0 then
                addpart(i*16,_y,0,0.4,0,10000,{1},0)
            else
                local _spr=16+flr(rnd(14))
                addpart((i*16)-4,_y-4,0,0.4,4,10000,{_spr},0)
            end
        end
    end

    if _t%15==0 then
        if _top then
            _y=-8
        else
            _y=-8+0.8*_t
        end
        for i=0,8 do
            addpart(8+i*16,_y,0,0.8,0,10000,{1},0)
        end
    end
end




--update functions
--main function
function _update60()
    doblink()
    doshake()
    updateparts()
    update_sash()
    if mode=="game" then
        update_game()
    elseif mode=="logo" then
        update_logo()
    elseif mode=="start" then
        update_start()
    elseif mode=="gameover" then
        update_gameover()
    elseif mode=="gameoverwait" then
        update_gameoverwait()
    elseif mode=="levelover" then
        update_levelover()
    elseif mode=="leveloverwait" then
        update_leveloverwait()
    elseif mode=="winner" then
        update_winner()
    elseif mode=="winnerwait" then
        update_winnerwait()
    end
end


function update_sash()
    if sash_v then
        sash_frames+=1
        if sash_delay_w>0 then
            sash_delay_w-=1
        else
            sash_w+=(sash_dw-sash_w)/5
            if abs(sash_dw-sash_w)<0.3 then
                sash_w=sash_dw
            end
        end

        --animate text
        if sash_delay_t>0 then
            sash_delay_t-=1
        else 
            sash_tx+=(sash_tdx-sash_tx)/10
            if abs(sash_tx-sash_tdx)<0.3 then
                sash_tx=sash_tdx
            end
        end

        --make sash go away
        if sash_frames==75 then
            sash_dw=0
            sash_tdx=160
            sash_delay_w=15
            sash_delay_t=0
        end
        if sash_frames>115 then
            sash_v=false
        end
    end
end


function update_logo()
    lcnt+=1
    if lcnt<100 then
        fadeto(0)
    else 
        fadeto(1)
        if fadeperc==1 then
            mode="start"
        end
    end
end


--win the game and wait for next steps
function update_winnerwait()
    govercountdown-=1
    if govercountdown<=0 then
        govercountdown=-1
        blinkspeed=4
        mode="winner"
    end
end


function update_winner()
    local _ang=rnd()
    local _dx=sin(_ang)*(rnd(0.5))
    local _dy=cos(_ang)*(rnd(0.5))
    local _mycol={12,12,5,5,0}
    local _toprow=40
    local _btnrow=_toprow+52

    addpart(flr(rnd(128)),_toprow,_dx,_dy,5,120+rnd(15),_mycol,3+rnd(6))
    addpart(flr(rnd(128)),_btnrow,_dx,_dy,5,120+rnd(15),_mycol,3+rnd(6))

    if govercountdown<0 then
        if loghs then
            if btnp(0) then
                sfx(17)
                nit_sel-=1
                if nit_sel<1 then
                    nit_sel=4
                end
            end
            if btnp(1) then
                sfx(17)
                nit_sel+=1
                if nit_sel>4 then
                    nit_sel=1
                end
            end
            if btnp(2) then
                if nit_sel<4 then
                    sfx(16)
                    nitials[nit_sel]-=1
                    if nitials[nit_sel]<1 then
                        nitials[nit_sel]=#hschars
                    end
                end
            end
            if btnp(3) then
                if nit_sel<4 then
                    sfx(16)
                    nitials[nit_sel]+=1
                    if nitials[nit_sel]>#hschars then
                        nitials[nit_sel]=1
                    end
                end
            end
            if btnp(5) then
                if nit_sel==4 then
                    addhs(points,points2,nitials[1],nitials[2],nitials[3])
                    savehs()
                    govercountdown=80
                    blinkspeed=1
                    sfx(15)
                end
            end
        else
            if btnp(4) then
                govercountdown=80
                blinkspeed=1
                sfx(15)
            end
        end
    else
        govercountdown-=1
        fadeperc=(80-govercountdown)/80
        if govercountdown<=0 then
            govercountdown=-1
            blinkspeed=8
            mode="start"
            part={}
            startparts()
            hs_x=128
            hs_dx=0
        end
    end
end


function update_start()
    --raining particles
    parttimer=parttimer+1
    spawnbgparts(true,parttimer)
    --slide the high score list
    if hs_x~=hs_dx then
        hs_x+=(hs_dx-hs_x)/5
        if abs(hs_dx-hs_x)<0.3 then
            hs_x=hs_dx
        end
    end

    if startcountdown<0 then
        --fade in game
        if not(pirate) then
            if btnp(5) then
                startcountdown=80
                blinkspeed=1
                sfx(12)
                music(-1,2000)
            end
            if btnp(3) or btnp(2) then
                fastmode=not fastmode
                sfx(16)
            end
            if btnp(0) then
                if hs_dx==128 then
                    hs_dx=0
                    sfx(20)
                end
            end
            if btnp(1) then
                if hs_dx==0 then
                    hs_dx=128
                    sfx(20)
                end
            end
        end
    else
        startcountdown-=1
        fadeperc=(80-startcountdown)/80
        if startcountdown<=0 then
            startcountdown-=1
            blinkspeed=8
            part={}
            startgame()
        end
    end
end


function update_gameover()
    local _ang=rnd()
    local _dx=sin(_ang)*(rnd(0.3))
    local _dy=cos(_ang)*(rnd(0.3))
    local _mycol={0,0,2,8}
    local _toprow=60
    local _btnrow=81

    addpart(flr(rnd(128)),_toprow,_dx,_dy,5,70+rnd(15),_mycol,3+rnd(6))
    addpart(flr(rnd(128)),_btnrow,_dx,_dy,5,70+rnd(15),_mycol,3+rnd(6))

    if govercountdown<0 then
        if btnp(5) or btnp(1) then
            govercountdown=80
            blinkspeed=1
            sfx(12)
            goverrestart=true
        end
        if btnp(4) or btnp(0) then
            govercountdown=80
            blinkspeed=1
            sfx(12)
            goverrestart=false
        end
    else
        govercountdown-=1
        fadeperc=(80-govercountdown)/80
        if govercountdown<=0 then
            if goverrestart then
                govercountdown=-1
                blinkspeed=8
                part={}
                restartlevel()
            else
                govercountdown=-1
                blinkspeed=8
                mode="start"
                part={}
                startparts()
                hs_x=128
                hs_dx=128
                music(1)
            end
        end
    end
end


function update_gameoverwait()
    govercountdown-=1
    if govercountdown<=0 then
        govercountdown=-1
        mode="gameover"
    end
end


function update_leveloverwait()
    govercountdown-=1
    if govercountdown<=0 then
        govercountdown=-1
        mode="levelover"
    end
end


function update_levelover()
    local _ang=rnd()
    local _dx=sin(_ang)*(rnd(0.3))
    local _dy=cos(_ang)*(rnd(0.3))
    local _mycol={12,12,5,5,0}
    local _toprow=60
    local _btnrow=75
    addpart(flr(rnd(128)),_toprow,_dx,_dy,5,70+rnd(15),_mycol,3+rnd(6))
    addpart(flr(rnd(128)),_btnrow,_dx,_dy,5,70+rnd(15),_mycol,3+rnd(6))

    if govercountdown<0 then
        if btnp(5) or btnp(1) then
            govercountdown=80
            blinkspeed=1
            sfx(15)
        end
    else
        govercountdown-=1
        fadeperc=(80-govercountdown)/80
        if govercountdown<=0 then
            govercountdown= -1
            blinkspeed=8
            part={}
            nextlevel()
        end 
    end
end


function fadeto(_f)
    --fade in game
    if fadeperc!=_f then
        if abs(fadeperc-_f)<0.05 then
            fadeperc=_f
        else
            fadeperc=fadeperc+(0.05*sgn(_f-fadeperc))
        end
    end
end



function update_game()
    local buttpress=false
    local nextx,nexty,brickhit
    fadeto(0)

    --infinite loop protection
    if timer_slow>0 then
        infcounter+=0.5
    else
        infcounter+=1
    end

    if timer_expand>0 then
        --check if pad should grow
        pad_w=flr(pad_wo*1.5)
    elseif timer_reduce>0 then
        --check if pad should shrink
        pad_w=flr(pad_wo/2)
        pointsmult=2
    else
        pad_w=pad_wo
        pointsmult=1
    end

    if btn(0) then
        --left
        pad_dx=-2.5
        buttpress=true
        pointstuck(-1)
    end
    if btn(1) then
        --right
        pad_dw=2.5
        buttpress=true
        pointstuck(1)
    end
    if btnp(5) then
        releasestuck()
    end
    if btnp(4) then
        --nectlevel()
    end

    if not(buttpress) then
        pad_dx=pad_dx/1.3
        spdwind=0
    else
        spdwind+=1
    end
 
    pad_x+=pad_dx
    local oldx = pad_x
    pad_x=mid(pad_w/2,pad_x,127-(pad_w/2))
    if pad_x!=oldx then
        spdwind=0
    end
 
    if spdwind>5 then
        if pad_dx < 0 then
            spawnspeedline(pad_x+(pad_w/2),pad_y)
        else
            spawnspeedline(pad_x-((pad_w/2)+2.5),pad_y)
        end
    end
  
    -- big ball loop
    for bi=#ball,1,-1 do
        updateball(bi)
    end
    for bi=#ball,1,-1 do
        --check if paddle rammed ball
        padramcheck(ball[bi])
    end
 
    -- move pills
    -- check collision for pills
    for i=#pill,1,-1 do
        pill[i].y+=0.7
        if pill[i].y > 128 then
            -- remove pill
            del(pill,pill[i])
        elseif box_box(pill[i].x,pill[i].y,8,6,pad_x-(pad_w/2),pad_y,pad_w,pad_h) then
            powerupget(pill[i].t)
            spawnpillpuft(pill[i].x,pill[i].y,pill[i].t)
            -- remove pill
            del(pill,pill[i])
            sfx(11)
        end
    end
 
    update_sd()
 
    checkexplosions()
 
    if levelfinished() then
        _draw()
        if levelnum >= #levels then
            wingame()
        else
            levelover()
        end
    end
 
    -- powerup timers
    if timer_mega > 0 then
        timer_mega-=1
    end
    if timer_mega_w > 0 then
        timer_mega_w-=1
    end 
    if timer_slow > 0 then
        timer_slow-=1
    end
    if timer_expand > 0 then
        timer_expand-=1
    end
    if timer_reduce > 0 then
        timer_reduce-=1
    end
 
    --animate bricks
    animatebricks()  
end



--draw function
function _draw()
    if mode=="game" then
        draw_game()
    elseif mode=="logo" then
        draw_logo()
    elseif mode=="start" then
        draw_start()
    elseif mode=="gameoverwait" then
        draw_game() 
    elseif mode=="gameover" then
        draw_gameover()
    elseif mode=="levelover" then
        draw_levelover()
    elseif mode=="leveloverwait" then
        draw_game()
    elseif mode=="winner" then
        draw_winner()
    elseif mode=="winnerwait" then
        draw_game() 
    end
    -- fade the screen
    pal()
    if fadeperc ~= 0 then
        fadepal(fadeperc)
    end
end
 
function draw_logo()
    cls(12)
    --rect(0,0,128,128,12)
    sspr(56,32,50,50,39,39)
end
 
function draw_sash()
    local _c,i
    if sash_v then
        if sash_c==-1 then
            _c = blink_r
        else
        _c = sash_c
        end
        rectfill(0,64-sash_w,128,64+sash_w,_c)
        print(sash_text,sash_tx,62,sash_tc)
        clip(0,64-sash_w,128,sash_w*2+1)
        for i=1,#ball do
            circfill(ball[i].x,ball[i].y,2,sash_tc)
        end
        clip()
    end
end
 
function draw_winner()
    -- draw game underneath sash
    draw_game()
 
    if loghs then
        --won. type in name
        --for highscore list
        local _y=40
        rectfill(0,_y,128,_y+52,12)
        print("★congratulations!★",26,_y+4,1)
        print("you have beaten the game",15,_y+14,7)
        print("enter your initials",15,_y+20,7)
        print("for the high score list.",15,_y+26,7)
        local _colors = {7,7,7,7}
        _colors[nit_sel] = blink_b
        print(hschars[nitials[1]],53,_y+34,_colors[1])
        print(hschars[nitials[2]],57,_y+34,_colors[2])
        print(hschars[nitials[3]],61,_y+34,_colors[3])
        print("ok",69,_y+34,_colors[4])
 
        print("use ⬅️➡️⬆️⬇️❎",35,_y+42,6)
    else
        --won but no highscore
        local _y=40
        rectfill(0,_y,128,_y+52,12)
        print("★congratulations!★",26,_y+4,1)
        print("you have beaten the game",15,_y+14,7)
        print("but your score is too low",15,_y+20,7)
        print("for the high score list.",15,_y+26,7)
        print("try again!",15,_y+32,7)
 
        print("press ❎ for main menu",20,_y+42,blink_b)
    end
end
 
function draw_start()
    cls()
 
    -- particles
    drawparts()
 
    --draw logo
    palt(14,true)
    spr(64,(hs_x-128)+36,10,7,5)
    palt()
    print("game dev tutorial at",25+(hs_x-128),50,2)
    print("youtube.com/lazydevs",25+(hs_x-128),56,2)
 
    print("music by grubermusic",25+(hs_x-128),64,2)
    print("patreon.com/gruber99",25+(hs_x-128),70,2)
 
    prinths(hs_x)
    if hs_x>=0 and not(pirate) then
        if fastmode then
            print("fast mode",46,84,blink_w)
        end  
 
        print("press ❎ to start",30,92,blink_g)
        print("press ⬆️⬇️ to toggle fast mode",4,115,3)
        if hs_x==128 then
            print("press ⬅️ for high score list",9,109,3)
        end
    end
 
    if (pirate) print(stat(102),9,109,1)
end
 
function draw_gameover()
    -- draw particles
    draw_game()
 
    local _c1, _c2
    rectfill(0,60,128,81,0)
    print("game over",46,62,7)
    if govercountdown<0 then
        _c1=blink_w
        _c2=blink_w
    else
        if goverrestart then
            _c1=blink_w
            _c2=5
        else
            _c2=blink_w
            _c1=5
        end
    end
    print("press ❎ or ➡️ to retry level",8,68,_c1)
    print("press 🅾️ or ⬅️ for main menu",8,74,_c2)
end
 
function draw_levelover()
    draw_game()
 
    rectfill(0,60,128,75,12)
    print("stage clear!",46,62,1)
    print("press ❎ or ➡️ to continue",12,68,blink_b)
end
 
function draw_game()
    local i
    cls()
    --cls(1)
    rectfill(0,0,127,127,1)
 
    --draw brick
    local _bsprite=false
    local _bspritex=64
 
    for i=1,#bricks do
        local _b=bricks[i]
        if _b.v or _b.fsh>0 then
            if _b.fsh>0 then
                brickcol = 7
                _b.fsh-=1
            elseif _b.t == "b" then
                brickcol = 14
                _bsprite=false
            elseif _b.t == "i" then
                brickcol = 6
                _bsprite=true
                _bspritex=74
            elseif _b.t == "h" then
                brickcol = 15
                _bsprite=true
                _bspritex=94
            elseif _b.t == "s" then
                brickcol = 9
                _bsprite=true
                _bspritex=64
            elseif _b.t == "p" then
                brickcol = 12
                _bsprite=true
                _bspritex=84
            elseif _b.t == "z" or bricks[i].t == "zz" then
                brickcol = 7
            end
            local _bx = _b.x+_b.ox
            local _by = _b.y+_b.oy
            if _bsprite and _b.fsh==0 then
                palt(0,false)
                sspr(_bspritex,0,10,5,_bx,_by)
                palt()
            else
                rectfill(_bx,_by,_bx+brick_w,_by+brick_h,brickcol)
            end 
        end
    end 
 
    -- particles
    drawparts()
 
    -- pills
    for i=1,#pill do
        palt(0,false)
        palt(13,true)
        spr(pill[i].t,pill[i].x,pill[i].y)
        palt()
    end
 
    -- balls
    for i=1,#ball do
        local _ballspr=34
        if timer_mega_w>0 or timer_mega>0 then
            _ballspr=35
        end
        palt(1,true)
        spr(_ballspr,ball[i].x-3,ball[i].y-3)
        palt()
        if ball[i].stuck then
            -- draw trajectory preview dots
            pset(ball[i].x+ball[i].dx*4*arrm,
                ball[i].y+ball[i].dy*4*arrm,
            10)
            pset(ball[i].x+ball[i].dx*4*arrm2,
                ball[i].y+ball[i].dy*4*arrm2,
            10) 
        end
    end
 
    --pad
    local _px=pad_x-(pad_w/2)
    palt(1,true)
    if not(sticky) then
        sspr(0,16,5,6,_px,pad_y)
        sspr(8,16,5,6,_px+pad_w-4,pad_y)
        for i=5,pad_w-5 do
            sspr(5,16,1,6,_px+i,pad_y)
        end 
    else
        sspr(0,24,6,8,_px-1,pad_y-1)
        sspr(9,24,6,8,_px+pad_w-4,pad_y-1)
        for i=5,pad_w-5 do
            sspr(6,24,1,8,_px+i,pad_y-1)
        end 
    end
 
    palt()
 
    --ui
    rectfill(0,0,128,6,0)
    if debug!="" then
        print(debug,1,1,7)  
    else
        print("lives:"..lives,1,1,7)
        print("score:"..pointstring(points2,points),60,1,7)
        local _ct=chain.."x"
        local _cc=7
        if timer_reduce>0 then
            _ct=(chain*10).."x"
            _cc=8
        end
        print(_ct,126-(#_ct*4),1,_cc)
    end
 
    draw_sash()
end
 
function pointstring(s2,s1)
    if (s1==0 and s2==0) return "0"
    local ret=""
    if s2>0 then
        ret=ret..s2
        if s1==0 then
            ret=ret.."0000"
        elseif s1<10 then
            ret=ret.."000"..s1
        elseif s1<100 then
            ret=ret.."00"..s1
        elseif s1<1000 then
            ret=ret.."0"..s1
        else
            ret=ret..s1
        end
    else
        ret=ret..s1
    end
    ret=ret.."0"
    return ret
end