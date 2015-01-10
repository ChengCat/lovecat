React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')

NumberGroup = React.createClass
    render: ->
        data = _.sortBy @props.data, 'k'
        <div>
            <div className='group-name'>
                <div className='bar'>&nbsp;</div>
                <div className='group-scope'>
                    <widgets.Scope scope={_.initial(@props.data[0].k)} />
                </div>
            </div>
            {
                data.map (X, K) =>
                    name = _.last(X.k)
                    scope = X.k
                    <div key={name} className='group-entry'>
                        <div className='group-entry-header'>{name}</div>
                        <div className='group-entry-content'>
                            <widgets.Slider val={X.v} onchange={(v)=>@props.onchange(scope, v)}/>
                        </div>
                    </div>
            }
        </div>

NumberPage = React.createClass
    getInitialState: ->
        filter: ''

    onchange: (val) ->
        @props.onchange String(val) if @props.onchange

    onfilter: (evt) ->
        @setState filter:evt.target.value

    render: ->
        input = @state.filter
        data = _.filter(@props.data, ((v) -> utils.scope_contains input, v.k))
        data = _.groupBy data, (x) -> _.initial(x.k)
        groups = _.keys(data).sort()

        <div>
            <div className='page-header'>
                <div className='page-title'>
                    <widgets.Scope scope={@props.scope} />
                </div>
                <div className='page-filter'>
                    <input type='text' placeholder='type to filter..' value={@state.filter} onChange={@onfilter}/>
                </div>
                &nbsp;
            </div>
        {
            groups.map (X, K) =>
                <div key={K}>
                    <NumberGroup data={data[X]} onchange={@props.onchange}/>
                </div>
        }
        {
            if groups.length is 0
                <div className='no-results'>
                    no such parameters.
                </div>
        }
        </div>

module.exports = NumberPage