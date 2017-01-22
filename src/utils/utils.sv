package utils;

    //function calculating ceiling of base 2 logarithm
    function integer clogb2;
    input [31:0] value;
    integer i;
    begin
        clogb2 = 0;
        for(i = 0; 2**i < value; i = i + 1)
            clogb2 = i + 1;
    end
    endfunction
   
endpackage