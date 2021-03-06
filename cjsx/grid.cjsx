React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
Color = require('color')
Deque = require 'double-ended-queue'

grid_size = 30

build_char_color = ->
    C = {}
    D = {}
    color = Color()
    hsv = (h,s,v) ->
        color.hsv(h,s,v).rgbString()

    mid = (l,r, n, x) ->
        l + (r-l) / n * x

    # digits
    for c in [48..58]
        x = (c-48)
        C[String.fromCharCode(c)] = hsv(x, 0, mid(95, 60, 10, x))
        D[String.fromCharCode(c)] = hsv(x, 0, mid(55, 20, 10, x))

    # upper-case
    for c in [65..91]
        x = 360 / 26 * (c-65)
        C[String.fromCharCode(c)] = hsv(x, 55, 100)
        D[String.fromCharCode(c)] = hsv(x, 70, 60)

    # lower-case
    for c in [97..123]
        x = 360 / 26 * (c-97)
        C[String.fromCharCode(c)] = hsv(x, 10, 100)
        D[String.fromCharCode(c)] = hsv(x, 60, 80)

    # others
    others = [].concat([33...48], [58...65], [91...97], [123...127])
    console.log others.length
    for i in [0...others.length]
        c = String.fromCharCode(others[i])
        x = 360 / others.length * i
        C[c] = hsv(x, 100, 50)
        D[c] = hsv(x, 0, 100)

    return [C,D]

[char_colors_bg, char_colors_fg] = build_char_color()

SingleGridPage = React.createClass
    getInitialState: ->
        lower_r: -30
        upper_r: 30
        lower_c: -30
        upper_c: 30

        view_r: null
        view_c: null
        view_r0: 0
        view_c0: 0

        sel_A: null
        sel_B: null

        data_hash: null

        last_move: null

    build_data_hash: (data) ->
        if @current_data? and not data.do_not_record
            @undo_push(@current_data)
        delete data.do_not_record
        @current_data = data
        data_hash = {}
        for x in data
            [r,c,s] = x
            if not data_hash[r]?
                data_hash[r] = {}
            data_hash[r][c] = s
        @setState data_hash: data_hash

    get_data: (r, c) ->
        return ' ' if not @state.data_hash[r]?
        return ' ' if not @state.data_hash[r][c]?
        return @state.data_hash[r][c]

    set_view_size: ->
        view_width = document.documentElement.clientWidth
        view_height = document.documentElement.clientHeight
        view_width -= 60
        view_height -= 180
        view_r = Math.floor(view_height/grid_size)
        view_c = Math.floor(view_width /grid_size)
        if view_r isnt @state.view_r or view_c isnt @state.view_c
            @setState
                view_r: view_r
                view_c: view_c
                sel_A: [0, 0]
                sel_B: [0, 0]
        if @refs.border?
            border = @refs.border.getDOMNode()
            border.style.width  = grid_size * view_c + 1 + 'px'
            border.style.height = grid_size * view_r + 1 + 'px'

    sanitize_coord: (r, c) ->
        if r < 0 then r = 0
        if r >= @state.view_r then r = @state.view_r-1
        if c < 0 then c = 0
        if c >= @state.view_c then c = @state.view_c-1
        return [r,c]

    sane_coord: (r, c) ->
        return false if r < 0
        return false if r >= @state.view_r
        return false if c < 0
        return false if c >= @state.view_c
        return true

    move_viewport: (r0, c0) ->
        if r0 isnt @state.view_r0 or c0 isnt @state.view_c0
            [Ar, Ac] = @state.sel_A
            [Br, Bc] = @state.sel_B
            [Ar, Ac] = @sanitize_coord(Ar+@state.view_r0-r0, Ac+@state.view_c0-c0)
            [Br, Bc] = @sanitize_coord(Br+@state.view_r0-r0, Bc+@state.view_c0-c0)
            @setState
                view_r0: r0
                view_c0: c0
                sel_A: [Ar, Ac]
                sel_B: [Br, Bc]

    componentWillMount: ->
        do @set_view_size
        @build_data_hash(@props.data)

    componentWillReceiveProps: (new_props) ->
        @build_data_hash(new_props.data)

    undo_push: (state) ->
        if not @undo_stack?
            @undo_stack = new Deque()
        if not @redo_stack?
            @redo_stack = new Deque()
        @redo_stack.clear()
        @undo_stack.push(state)
        if @undo_stack.length > 100
            @undo_stack.shift()

    componentDidMount: ->
        do @set_view_size
        window.addEventListener('resize', @set_view_size)
        window.addEventListener('mousedown', @onmousedown)
        window.addEventListener('mousemove', @onmousemove)
        window.addEventListener('contextmenu', @oncontextmenu)
        window.addEventListener('touchstart', @ontouchstart)
        window.addEventListener('keypress', @onkeypress)
        window.addEventListener('keydown', @onkeydown)
        window.addEventListener('wheel', @onwheel)
        window.addEventListener('mousescroll', @onwheel)
        window.addEventListener('beforecopy', @onbeforecopy)
        window.addEventListener('beforepaste', @onbeforepaste)
        window.addEventListener('beforecut', @onbeforecut)
        window.addEventListener('copy', @oncopy)
        window.addEventListener('paste', @onpaste)
        window.addEventListener('cut', @oncut)

    componentWillUnmount: ->
        window.removeEventListener('resize', @set_view_size)
        window.removeEventListener('mousedown', @onmousedown)
        window.removeEventListener('mousemove', @onmousemove)
        window.removeEventListener('contextmenu', @oncontextmenu)
        window.removeEventListener('touchstart', @ontouchstart)
        window.removeEventListener('keypress', @onkeypress)
        window.removeEventListener('keydown', @onkeydown)
        window.removeEventListener('wheel', @onwheel)
        window.removeEventListener('mousescroll', @onwheel)
        window.removeEventListener('beforecopy', @onbeforecopy)
        window.removeEventListener('beforepaste', @onbeforepaste)
        window.removeEventListener('beforecut', @onbeforecut)
        window.removeEventListener('copy', @oncopy)
        window.removeEventListener('paste', @onpaste)
        window.removeEventListener('cut', @oncut)

    onbeforecopy: (e) ->
        e.preventDefault()

    onbeforecut: (e) ->
        e.preventDefault()

    onbeforepaste: (e) ->
        e.preventDefault()

    oncopy: (e) ->
        [r1, c1, r2, c2] = @get_sel_box_data()
        data = @clipboard_get_data(r1,c1, r2,c2)
        e.clipboardData.setData('text/plain', data)
        e.preventDefault()

    onpaste: (e) ->
        [r1, c1, r2, c2] = @get_sel_box_data()
        data = e.clipboardData.getData('text/plain')
        data = @clipboard_parse(data)
        return if not data?
        r2 = Math.min(r2, r1+data.length-1)
        c2 = Math.min(c2, c1+data[0].length-1)
        @apply_update(r1,c1, r2,c2, (r,c,o) ->
            d = data[r-r1][c-c1]
            if d is ' ' then o else d
        )
        e.preventDefault()

    oncut: (e) ->
        [r1, c1, r2, c2] = @get_sel_box_data()
        data = @clipboard_get_data(r1,c1, r2,c2)
        e.clipboardData.setData('text/plain', data)
        @apply_update(r1,c1, r2,c2, -> ' ')
        e.preventDefault()

    mouse_to_view: (evt) ->
        r = evt.pageY - utils.ele_top(@refs.table.getDOMNode()) - 1
        c = evt.pageX - utils.ele_left(@refs.table.getDOMNode()) - 1
        r = Math.floor(r/grid_size)
        c = Math.floor(c/grid_size)
        return [r,c]

    oncontextmenu: (evt) ->
        evt.preventDefault()

    ontouchstart: (evt) ->
        evt.is_touch = true
        evt.preventDefault = ->
        @onmousedown(evt)

    onmousemove: (evt) ->
        [r,c] = @mouse_to_view(evt)
        if @sane_coord(r,c)
            [r,c] = @view_to_data(r,c)
            cursor = [r,c]
        else
            cursor = null
        if not _.isEqual(cursor, @state.cursor_position)
            @setState cursor_position: cursor

    onmousedown: (evt) ->
        [r,c] = @mouse_to_view(evt)

        if evt.ctrlKey or evt.button is 2 or evt.is_touch
            [@moving_r, @moving_c] = [r,c]
            @moving_r0 = @state.view_r0
            @moving_c0 = @state.view_c0
            @moving_speed = if evt.shiftKey or evt.altKey then 3 else 1
            evt.preventDefault()
            window.addEventListener('mousemove', @move_onmousemove)
            window.addEventListener('mouseup', @move_onmouseup)
            window.addEventListener('touchmove', @move_ontouchmove)
            window.addEventListener('touchend', @move_ontouchend)
        else
            return if not @sane_coord(r, c)
            @setState
                sel_A: [r,c]
                sel_B: [r,c]
                last_move: null
            evt.preventDefault()
            window.addEventListener('mousemove', @sel_onmousemove)
            window.addEventListener('mouseup', @sel_onmouseup)

    move_ontouchmove: (evt) ->
        proxy_evt =
            pageX: evt.touches[0].pageX
            pageY: evt.touches[0].pageY
            clientX: evt.touches[0].clientX
            clientY: evt.touches[0].clientY
        @move_onmousemove(proxy_evt)
        evt.preventDefault()

    move_ontouchend: (evt) ->
        @move_onmouseup()

    move_onmousemove: (evt) ->
        [r,c] = @mouse_to_view(evt)
        dr = (r - @moving_r) * @moving_speed
        dc = (c - @moving_c) * @moving_speed
        now_r0 = @moving_r0 - dr
        now_c0 = @moving_c0 - dc
        @move_viewport(now_r0, now_c0)

    move_onmouseup: (evt) ->
        window.removeEventListener('mousemove', @move_onmousemove)
        window.removeEventListener('mouseup', @move_onmouseup)
        window.removeEventListener('touchmove', @mose_ontouchmove)
        window.removeEventListener('touchend', @move_ontouchend)

    onwheel: (evt) ->
        switch
            when evt.wheelDeltaX?
                delta_r = -evt.wheelDeltaY / 40
                delta_c = evt.wheelDeltaX / 40
            when evt.deltaX?
                delta_r = evt.deltaY
                delta_c = evt.deltaX
        delta_r = Math.round(delta_r)
        delta_c = Math.round(delta_c)
        if (evt.shiftKey or evt.altKey) and delta_c is 0
            [delta_r, delta_c] = [delta_c, delta_r]
        @move_viewport(@state.view_r0 + delta_r, @state.view_c0 + delta_c)

    sel_onmousemove: (evt) ->
        [r,c] = @mouse_to_view(evt)
        [r,c] = @sanitize_coord(r, c)
        @setState sel_B: [r,c]

    sel_onmouseup: (evt) ->
        window.removeEventListener('mousemove', @sel_onmousemove)
        window.removeEventListener('mouseup', @sel_onmouseup)

    move_sel: (dr, dc, resize_sel, speed=1) ->
        if resize_sel
            [r,c] = @state.sel_B
            [r,c] = [r+dr*speed, c+dc*speed]
            [r,c] = @sanitize_coord(r,c)
            @setState sel_B: [r,c]
        else
            dr *= Math.abs(@state.sel_A[0] - @state.sel_B[0]) + 1
            dc *= Math.abs(@state.sel_A[1] - @state.sel_B[1]) + 1
            dr *= speed if Math.abs(dr) <= 1
            dc *= speed if Math.abs(dc) <= 1
            @setState
                sel_A: [@state.sel_A[0]+dr, @state.sel_A[1]+dc]
                sel_B: [@state.sel_B[0]+dr, @state.sel_B[1]+dc]
            if (not @sane_coord(@state.sel_A[0], @state.sel_A[1]) or
               not @sane_coord(@state.sel_B[0], @state.sel_B[1]))
                @move_viewport(@state.view_r0+dr, @state.view_c0+dc)
            @setState
                last_move: [dr, dc]

    # for special keys
    onkeydown: (evt) ->
        console.log evt
        speed = if evt.altKey then 5 else 1
        switch
            when evt.key == 'Down' or evt.keyIdentifier == 'Down'
                @move_sel(1, 0, evt.shiftKey, speed)
            when evt.key == 'Up' or evt.keyIdentifier == 'Up'
                @move_sel(-1, 0, evt.shiftKey, speed)
            when evt.key == 'Left' or evt.keyIdentifier == 'Left'
                @move_sel(0, -1, evt.shiftKey, speed)
            when evt.key == 'Right' or evt.keyIdentifier == 'Right'
                @move_sel(0, 1, evt.shiftKey, speed)
            when evt.key == 'Backspace' or evt.keyIdentifier == 'U+0008' or
                 evt.key == 'Del' or evt.key == 'Delete' or evt.keyIdentifier == 'U+007F'
                [r1,c1,r2,c2] = @get_sel_box_data()
                @apply_update(r1,c1, r2,c2, -> ' ')
            when (evt.key == 'h' or evt.keyIdentifier == 'U+0048' or
                  evt.key == 'u' or evt.keyIdentifier == 'U+0055') and evt.ctrlKey
                st = @undo_stack.pop()
                if st?
                    @redo_stack.push(@current_data)
                    # the 'do_not_record' tag is retained during local updates
                    st.do_not_record = true
                    @props.onchange @props.scope, st
            when (evt.key == 'l' or evt.keyIdentifier == 'U+004C' or
                  evt.key == 'r' or evt.keyIdentifier == 'U+0052') and evt.ctrlKey
                st = @redo_stack.pop()
                if st?
                    @undo_stack.push(@current_data)
                    st.do_not_record = true
                    @props.onchange @props.scope, st
            when (evt.key == 'o' or evt.keyIdentifier == 'U+004F') and evt.ctrlKey
                @move_viewport(0, 0)
            else
                return
        evt.preventDefault()

    # for grid cotents
    onkeypress: (evt) ->
        ascii = evt.which
        return if not (32 <= ascii and ascii <= 126)
        ch = String.fromCharCode(evt.which)

        [r1,c1,r2,c2] = @get_sel_box_data()
        @apply_update(r1,c1, r2,c2, -> ch)

        if @state.last_move?
            if (r1 is r2 and @state.last_move[1] is 0) or
               (c1 is c2 and @state.last_move[0] is 0)
                @move_sel(@state.last_move[0], @state.last_move[1])

    view_to_data: (r,c) ->
        rc = Math.floor(@state.view_r/2)
        cc = Math.floor(@state.view_c/2)
        r = @state.view_r0 + r-rc
        c = @state.view_c0 + c-cc
        return [r,c]

    get_sel_box_view: ->
        r1 = @state.sel_A[0]
        r2 = @state.sel_B[0]
        if r1>r2 then [r1,r2]=[r2,r1]
        c1 = @state.sel_A[1]
        c2 = @state.sel_B[1]
        if c1>c2 then [c1,c2]=[c2,c1]
        return [r1,c1,r2,c2]

    get_sel_box_data: ->
        [r1,c1,r2,c2] = @get_sel_box_view()
        [r1,c1] = @view_to_data(r1,c1)
        [r2,c2] = @view_to_data(r2,c2)
        return [r1,c1,r2,c2]

    fill_data: (r1,c1, r2,c2, func) ->
        res = []
        for r,vr of @state.data_hash
            for c,vc of vr
                if not (r1 <= r and r <= r2 and c1 <= c and c <= c2)
                    res.push([r,c,vc])
        for r in [r1...r2+1]
            for c in [c1...c2+1]
                x = func(r,c, @get_data(r,c))
                continue if x is ' '
                res.push([r,c,x])
        return res

    apply_update: (r1,c1, r2,c2, func) ->
        res = @fill_data(r1,c1, r2,c2, func)
        @props.onchange @props.scope, res

    clipboard_get_data: (r1,c1, r2,c2) ->
        res = []
        for r in [r1...r2+1]
            line = ''
            for c in [c1...c2+1]
                Row = @state.data_hash[r]
                if Row? and Row[c]?
                    line += Row[c]
                else
                    line += ' '
            res.push(line)
        res.push('')
        return res.join('\n')

    clipboard_parse: (s) ->
        ascii = (ch) -> ch.charCodeAt()
        do ->
        try
            s = s.split('\n')
            s = _(s).dropWhile((x) -> x is '').dropRightWhile((y) -> y is '').value()
            throw 'invalid' if (s.length is 0)
            throw 'invalid' if not _.every(s, (x) -> x.length is s[0].length)
            throw 'invalid' if not _.every(s, (x) -> /^[\x20-\x7e]*$/.test(x))
        catch error
            console.warn 'invalid clipboard data to paste', error
        return s

    render_marker: (n, style, rad) ->
        [r0,c0] = @view_to_data(0, 0)
        offset = (x, divisor) ->
            Math.ceil(x/divisor)*divisor - x
        r0 = offset(r0, n)
        c0 = offset(c0, n)
        pos = []
        for r in _.range(r0, @state.view_r+1, n)
            for c in _.range(c0, @state.view_c+1, n)
                pos.push([r, c])
        pos.map ([r, c], K) ->
            <div className='marker' key={K} style={
                x = c * grid_size
                y = r * grid_size
                left:   x
                top:    y
            }>
                <div className={style}/>
            </div>

    render: ->
        <div>
            <div className='grid-table-border' ref='border'>
                <div className='grid-table' ref='table'>
                    <div>
                    {
                        for r in [0...@state.view_r]
                            <div className='row' key={r}>
                            {
                                for c in [0...@state.view_c]
                                    [r1,c1] = @view_to_data(r,c)
                                    x = @get_data(r1,c1)
                                    if x is ' '
                                        color_fg = null
                                        color_bg = null
                                    else
                                        color_fg = char_colors_fg[x]
                                        color_bg = char_colors_bg[x]
                                    <div className='column' key={c} style={'backgroundColor':color_bg}>
                                        <div className='text' style={'color':color_fg}>
                                        {x}
                                        </div>
                                    </div>
                            }
                            </div>
                    }
                    </div>
                    <div className='grid-sel' ref='sel-box' style={
                        [r1,c1,r2,c2] = @get_sel_box_view()
                        left:   c1 * grid_size
                        top:    r1 * grid_size
                        height: (r2-r1+1) * grid_size-3
                        width:  (c2-c1+1) * grid_size-3
                    }/>
                    {
                        @render_marker(3, 'marker-2')
                    }
                    {
                        @render_marker(9, 'marker-4')
                    }
                </div>
            </div>
            <div className='status-bar'>
                <span className='status-visible'>
                    visible &nbsp;
                    <span className='status-val'>
                    {
                        [r1, c1] = @view_to_data(0, 0)
                        [r2, c2] = @view_to_data(@state.view_r-1, @state.view_c-1)
                        <span>
                            ({r1},{c1}) -- ({r2},{c2})
                        </span>
                    }
                    </span>
                </span>
                <span className='status-sel'>
                    selected &nbsp;
                    <span className='status-val'>
                    {
                        [r1,c1, r2,c2] = @get_sel_box_view()
                        <span>
                            {r2-r1+1} x {c2-c1+1}
                        </span>
                    }
                    </span>
                </span>
                {
                    if @state.cursor_position?
                        <span className='status-cursor'>
                            cursor &nbsp;
                            <span className='status-val'>
                            {
                                [r,c] = @state.cursor_position
                                <span>
                                    ({r}, {c})
                                </span>
                            }
                            </span>
                        </span>
                }
            </div>
        </div>

GridPage = React.createClass
    render: ->
        data = @props.data

        <div>
        {
            switch
                when data.length is 1
                    url_scope = utils.url_to_scope(document.location.pathname)
                    if not _.isEqual(url_scope, data[0].k)
                        document.location.pathname = utils.scope_to_url(data[0].k)
                    else
                        <SingleGridPage
                            scope={@props.data[0].k}
                            data={@props.data[0].v}
                            onchange={@props.onchange}/>
                when data.length > 1
                    data.map (X, K) =>
                        <div key={K} className='active-entry'>
                            <div className='ball'/>
                            <div className='entry-text'>
                                <widgets.Scope scope={X.k}/>
                            </div>
                        </div>
                when data.length is 0
                    if data.length is 0
                        <div className='no-results'>
                            no such parameters.
                        </div>
        }
        </div>

module.exports = GridPage