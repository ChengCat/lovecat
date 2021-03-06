React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
TablePage = require('./table')

mono_font = '"Liberation Mono", "Nimbus Mono L", "FreeMono", "DejaVu Mono", "Bitstream Vera Mono", "Lucida Console", "Andale Mono", "Courier New", monospace'

main_color = '#ed5f9f'
secondary_color = '#edad5f'

PointPage = React.createClass
    render: ->
        <TablePage
            data = {@props.data}
            onchange = {@props.onchange}
            table_position = { (dpr, W, H) ->
                size = Math.min(W-60, H-180)
                left = Math.floor((W-size)/2 * dpr)
                top  = Math.floor(150 * dpr)
                size *= dpr
                switch dpr
                    when 1
                        if size % 2 is 0 then size -= 1
                return [ left, top
                         size, size ]
            }
            data_to_screen = { ([x,y], L, T, W, H) ->
                x = L + W * (1+x)/2
                y = T + H * (1-y)/2
                return [x,y]
            }
            move_data = { ([x,y], x0,y0, x1,y1, L,T,W,H) ->
                [dx, dy] = [x1-x0, y1-y0]
                dx /= W/2
                dy /= -W/2

                [x, y] = [x+dx, y+dy]
                if x < -1 then x = -1
                if x > 1  then x = 1
                if y < -1 then y = -1
                if y > 1  then y = 1

                return [x,y]
            }
            select_threshold = { (touch, dpr) ->
                threshold = if touch then 20 else 5
                threshold *= dpr
                return threshold
            }
            draw_data_point = { (ctx, dpr, data, x,y, hover, selected) ->
                circle_r = 4 * dpr
                circle_r2 = 7 * dpr
                ctx.lineWidth = dpr

                if hover?
                    ctx.fillStyle = secondary_color
                else
                    ctx.fillStyle = main_color

                ctx.beginPath()
                ctx.arc(x, y, circle_r, 0, Math.PI*2)
                ctx.fill()

                if selected
                    ctx.strokeStyle = ctx.fillStyle
                    ctx.beginPath()
                    ctx.arc(x, y, circle_r2, 0, Math.PI*2)
                    ctx.stroke()
            }
            draw_data_label = { (ctx, dpr, data, x,y, hover, selected) =>
                ctx.fillStyle = '#555'
                label = utils.subscope_to_text(@props.scope, data.k)
                ctx.font = (9*dpr)+'pt ' + mono_font
                ctx.fillText(label, x+10*dpr, y-10*dpr)
            }
            draw_select_box = { (ctx, dpr, L,T,W,H) ->
                ctx.strokeStyle = main_color
                ctx.fillStyle = main_color

                ctx.globalAlpha = 0.05
                ctx.fillRect(L,T,W,H)
                ctx.globalAlpha = 0.7

                switch dpr
                    when 1, 1.5
                        ctx.lineWidth = 1
                        ctx.strokeRect(L+0.5,T+0.5,W-1,H-1)
                    else
                        ctx.lineWidth = 2
                        ctx.strokeRect(L,T,W,H)
            }
            bg_need_redraw = { (W,H, canvas) ->
                return if W is canvas.width and H is canvas.height
                '2d'
            }
            draw_bg = { (ctx, dpr, L,T,W,H) ->
                ctx.strokeStyle = '#bbb'

                switch dpr
                    when 1, 1.5
                        console.log L,T,W,H
                        ctx.lineWidth = 1
                        ctx.strokeRect(L+0.5,T+0.5,W-1,H-1)
                    else
                        ctx.lineWidth = 2
                        ctx.strokeRect(L,T,W,H)

                center_x = L+W/2
                center_y = T+H/2

                ctx.strokeStyle = '#ddd'
                ctx.setLineDash [6, 5]
                ctx.beginPath()
                ctx.moveTo(center_x, center_y)
                ctx.lineTo(center_x, T)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(center_x, center_y)
                ctx.lineTo(center_x, T+H)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(center_x, center_y)
                ctx.lineTo(L, center_y)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(center_x, center_y)
                ctx.lineTo(L+W, center_y)
                ctx.stroke()
            } />

module.exports = PointPage