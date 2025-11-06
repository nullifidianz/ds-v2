import zmq

req_address = "broker"
req_port = 5555

sub_address = "proxy"
sub_port = 5558

context = zmq.Context()

req_socket = context.socket(zmq.REQ)
req_socket.connect(f"tcp://{req_address}:{req_port}")

sub_socket = context.socket(zmq.SUB)
sub_socket.connect(f"tcp://{sub_address}:{sub_port}")
sub_socket.setsockopt_string(zmq.SUBSCRIBE, "")
