
using HttpServer
using WebSockets


# Construct a message responding to plot updates from the client.
function webshow_response(req::Vector{Uint8})
	req = JSON.parse(bytestring(req))
	backend_type = eval(symbol(req["backend"]["type"]))
	webshow_response(
        req["msg"],
		deserialize(Plot, req["plot"]),
		backend_type,
		float(req["backend"]["width"])*mm,
		float(req["backend"]["height"])*mm)
end


function webshow_response(msg, p::Plot, backend_type, width, height)
	out = IOBuffer(true, true)
	backend = backend_type(out, width, height, emit_on_finish=false)
	draw(backend, p)

	@sprintf("{\"msg\":\"%s\",
               \"plot\":%s,
		       \"graphic\":\"%s\",
		       \"backend\": {
		       		\"type\": \"%s\",
		       		\"width\": %f,
		       		\"height\": %f
		       }}",
             msg,
		     JSON.to_json(serialize(p)),
             bytestring(encode(Base64, takebuf_string(out))),
		     string(backend_type),
		     width / mm,
		     height / mm)
end


function webshow(p::Plot, backend_type=D3, width=210mm, height=148mm)
	resp = webshow_response("rupdat", p, backend_type, width, height)

	wsh = WebSocketHandler() do req, client
		write(client, resp)
		while true
			println(STDERR, "sending plot")
			write(client, webshow_response(read(client)))
		end
	end

	server = Server(wsh)
	println(STDERR, "starting server...")
	run(server, 8080)
end

