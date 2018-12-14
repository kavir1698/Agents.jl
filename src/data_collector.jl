"""
    agents_data_per_step(properties::Array{Symbol}, aggregators::Array{Function})

Collect data from a `property` of agents (a `fieldname`) and apply `aggregators` function to them.

If a fieldname of agents returns an array, this will use the `mean` of the array on which to apply aggregators.

"""
function agents_data_per_step(properties::Array{Symbol}, aggregators::Array, model::AbstractModel; step=1)    
  output = Array{Real}(undef, length(properties) * length(aggregators) + 1)
  output[1] = step
  agentslen = nagents(model)
  counter = 2
  for fn in properties
    if fn == :pos
      temparray = [coord_to_vertex(model.agents[i], model) for i in 1:agentslen]
    elseif typeof(getproperty(model.agents[1], fn)) <: AbstractArray
      temparray = [mean(getproperty(model.agents[i], fn)) for i in 1:agentslen]
    else
      temparray = [getproperty(model.agents[i], fn) for i in 1:agentslen]
    end
    for agg in aggregators
      output[counter] = agg(temparray)
      counter += 1
    end
  end
  colnames = hcat(["step"], [join([string(i[1]), split(string(i[2]), ".")[end]], "_") for i in product(properties, aggregators)])
  return output, colnames
end


"""
    agents_data_complete(properties::Array{Symbol}, model::AbstractModel)

Collect data from a `property` of agents (a `fieldname`) into a dataframe.

If a fieldname of agents returns an array, this will use the `mean` of the array
"""
function agents_data_complete(properties::Array{Symbol}, model::AbstractModel; step=1)
  # colnames = [join([string(i[1]), split(string(i[2]), ".")[end]], "_") for i in product(properties, aggregators)]
  dd = DataFrame()
  agentslen = nagents(model)
  for fn in properties
    if fn == :pos
      temparray = [coord_to_vertex(model.agents[i], model) for i in 1:agentslen]
    elseif typeof(getproperty(model.agents[1], fn)) <: AbstractArray
      temparray = [mean(getproperty(model.agents[i], fn)) for i in 1:agentslen]
    else
      temparray = [getproperty(model.agents[i], fn) for i in 1:agentslen]
    end
    dd[:id] = [i.id for i in model.agents]
    fieldname = Symbol(join([string(fn), step], "_"))
    dd[fieldname] = temparray
  end
  return dd
end

function data_collector(properties::Array{Symbol}, aggregators::Array{Function}, steps_to_collect_data::Array{Int64}, model::AbstractModel, step::Integer)
  d, colnames = agents_data_per_step(properties, aggregators, model, step=step)
  dict = Dict(Symbol(colnames[i]) => d[i] for i in 1:length(d))
  df = DataFrame(dict)
  return df
end

function data_collector(properties::Array{Symbol}, aggregators::Array{Function}, steps_to_collect_data::Array{Int64}, model::AbstractModel, step::Integer, df::DataFrame)
  d, colnames = agents_data_per_step(properties, aggregators, model, step=step)
  dict = Dict(Symbol(colnames[i]) => d[i] for i in 1:length(d))
  push!(df, dict)
  return df
end

function data_collector(properties::Array{Symbol}, steps_to_collect_data::Array{Int64}, model::AbstractModel, step::Integer)
  df = agents_data_complete(properties, model, step=step)
  return df
end

function data_collector(properties::Array{Symbol}, steps_to_collect_data::Array{Int64}, model::AbstractModel, step::Integer, df::DataFrame)
  d = agents_data_complete(properties, model, step=step)
  df = join(df, d, on=:id, kind=:outer)
  return df
end


"""
Writes a dataframe to file
"""
function write_to_file(;df::DataFrame, filename::AbstractString)
  CSV.write(filename, df, append=false, delim="\t", writeheader=true)
end