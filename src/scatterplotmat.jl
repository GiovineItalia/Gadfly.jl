




function scatterplotmatdata(df; colorid=nothing)
   
    if isa(colorid, Symbol)     
        colv = df[colorid]
        a = df[setdiff(names(df),[colorid])]
    elseif isa(colorid, Vector)
        colv = colorid
        a = df
    else
        colv = fill(1, size(df,1))
        a = df
    end
    

    if isa(df, DataFrame)
        varnames = map(string, names(a))
    else
        varnames= ["V$j" for j in 1:size(a,2)]
    end
   
    a = convert(Matrix, a)
    n,p = size(a)

    
    # Base matrix
    m = repmat(collect(1:p)', n)
    Dbase = vcat([ DataFrame(x=repmat(a[:,i],p), y=vec(a), col=repmat(colv,p),
        g1=i, g2=vec(m)  ) for i in 1:p ]...)
 
    # Point matrix
    Db= [ DataFrame(x=repmat(a[:,i],p-i), y=vec(a[:,(i+1):p]), 
            col=repmat(colv,p-i), g1=i, g2=vec(m[:,(i+1):p])) for i in 1:p ]
    Dc= [DataFrame(g2 = setdiff(1:p,Db[i][:g2]), g1=i, 
            x=NaN, y=NaN, col=colv[1])[:,[3,4,5,2,1]] for i in 1:p]
    D = vcat(Dc..., Db...)
    
    # Text matrix
    Dcor = by(Dbase,[:g1, :g2], x -> DataFrame(x=mean(x[:x]),y=mean(x[:y]), cor=cor(x[:x],x[:y])) )
    Dcor[:label] = map( x -> (@sprintf "%0.2f" x), Dcor[:cor])
    Dcor[vec(tril(trues(p,p))),:label] = ""

    
    # Histogram matrix
    Dh = vcat([DataFrame(x=a[:,i], col=colv , g1=i,g2=i) for i in 1:p]...)


    # Replace integer levels with varnames
    Dbase[:g1] = varnames[Dbase[:g1]]; Dbase[:g2] = varnames[Dbase[:g2]]
    D[:g1] = varnames[D[:g1]]; D[:g2] = varnames[D[:g2]]
    Dh[:g1] = varnames[Dh[:g1]]; Dh[:g2] = varnames[Dh[:g2]]
    Dcor[:g1] = varnames[Dcor[:g1]]; Dcor[:g2] = varnames[Dcor[:g2]]

    return Dbase, D, Dcor, Dh
end






