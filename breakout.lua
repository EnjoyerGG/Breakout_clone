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
    niitals={1,1,1}
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

    ball2=copyball(ognball)

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