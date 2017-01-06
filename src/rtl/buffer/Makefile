COMP = iverilog
SRC = circular_buffer.v tb_circular_buffer.v

all: 
	$(COMP) $(SRC)
	./a.out
	gtkwave out.vcd

clean:
	rm -f a.out
	rm -f	out.vcd