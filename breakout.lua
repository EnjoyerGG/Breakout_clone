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
        mage=_maxage,
        age=0,
        col=_col[1],
        colarr=_col,
        rot=0,
        rottimer=0,
        s=_s,
        os=_s
    })
end