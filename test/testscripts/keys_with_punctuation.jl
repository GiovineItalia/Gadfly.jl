using Gadfly

keys=["a.","b,","c/","d?","g;","h:","i'","l{","m|","p~","q!","r@","s#","t\$","u%","x*","y(","z_","A-","B=","C+"]

plot(y=collect(1:length(keys)), color=keys)
