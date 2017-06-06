package noc_params;

	localparam MESH_SIZE_X = 5;
	localparam MESH_SIZE_Y = 5;

	localparam DEST_ADDR_SIZE_X = $clog2(MESH_SIZE_X);
	localparam DEST_ADDR_SIZE_Y = $clog2(MESH_SIZE_Y);

	localparam VC_NUM = 2;
	localparam VC_SIZE = $clog2(VC_NUM);

	localparam HEAD_PAYLOAD_SIZE = 16;

	localparam FLIT_DATA_SIZE = DEST_ADDR_SIZE_X+DEST_ADDR_SIZE_Y+HEAD_PAYLOAD_SIZE;

	typedef enum logic [2:0] {LOCAL, NORTH, SOUTH, WEST, EAST} port_t;
	localparam PORT_NUM = 5;
	localparam PORT_SIZE = $clog2(PORT_NUM);

	typedef enum logic [1:0] {HEAD, BODY, TAIL, HEADTAIL} flit_label_t;

	typedef struct packed
	{
		logic [DEST_ADDR_SIZE_X-1 : 0] 	x_dest;
		logic [DEST_ADDR_SIZE_Y-1 : 0] 	y_dest;
		logic [HEAD_PAYLOAD_SIZE-1: 0] 	head_pl;
	} head_data_t;

	typedef struct packed
	{
		flit_label_t			flit_label;
		logic [VC_SIZE-1 : 0] 	vc_id;
		union packed
		{
			head_data_t 		head_data;
			logic [FLIT_DATA_SIZE-1 : 0] bt_pl;
		} data;
	} flit_t;

    typedef struct packed
    {
        flit_label_t flit_label;
        union packed
        {
            head_data_t head_data;
            logic [FLIT_DATA_SIZE-1 : 0] bt_pl;
        } data;
    } flit_novc_t;

endpackage