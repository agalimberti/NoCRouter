package noc_params;

	/*
	The mesh is assumed to have a square topology
	*/
	localparam MESH_SIZE = 5;
	localparam DEST_ADDR_SIZE = $clog2(MESH_SIZE);

	localparam VC_NUM = 2;
	localparam VC_SIZE = $clog2(VC_NUM);

	localparam HEAD_PAYLOAD_SIZE = 16;
	
	localparam FLIT_DATA_SIZE = VC_SIZE+2*DEST_ADDR_SIZE+HEAD_PAYLOAD_SIZE;

	typedef enum logic [2:0] {CENTER, UP, DOWN, LEFT, RIGHT} outport_t;

	typedef enum logic [1:0] {HEAD, BODY, TAIL} flit_label_t;
	
	typedef struct packed
	{
		logic [VC_SIZE-1 : 0] 			vc_id;
		logic [DEST_ADDR_SIZE-1 : 0] 	x_dest;
		logic [DEST_ADDR_SIZE-1 : 0] 	y_dest;
		logic [HEAD_PAYLOAD_SIZE-1: 0] 	head_pl;
	} head_data_t;
	
	typedef logic [FLIT_DATA_SIZE-1 : 0] body_tail_payload_t;
	
	typedef struct packed 
	{
		flit_label_t			flit_label;
		union packed
		{
			head_data_t 		head_data;
			body_tail_payload_t bt_pl;	
		} data;
	} flit_t;

endpackage