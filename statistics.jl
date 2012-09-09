
abstract Statistic


type IdentityStatistic
    aes::Vector{Symbol}
end

function apply_stat(stat::IdentityStatistic, scaled_data::Aesthetics)
    scaled_data
end


