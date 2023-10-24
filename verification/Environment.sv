`include "Packet.sv"
`include "Generator.sv"
`include "Driver.sv"
`include "Monitor.sv"
`include "Scoreboard.sv"

class environment;
    generator gen;
    mailbox gen_drv_mailbox;
    driver drv;
    virtual DUT_interface vintrf;
    monitor mntr;
    mailbox mntr_scrbrd_mailbox;
    scoreboard scrbrd;
    
    function new(virtual DUT_interface vintrf);
        this.vintrf = vintrf;
        gen_drv_mailbox = new;
        mntr_scrbrd_mailbox = new;
        gen = new(gen_drv_mailbox);
        drv = new(gen_drv_mailbox, vintrf);
        mntr = new(mntr_scrbrd_mailbox, vintrf);
        scrbrd = new(mntr_scrbrd_mailbox);
    endfunction
    
    task run;
        test;
        post_test;
        $finish;
    endtask
    
    task test;
        fork
            gen.dispatch;
            drv.drive;
            mntr.watch;
            scrbrd.evaluate;
        join_any
    endtask
    
    task post_test;
        wait(gen.generation_ended.triggered); // wait for generator to generate all packets
        wait(gen.packet_count == drv.signals_driven);
        wait(drv.signals_driven == mntr.signals_received);
        wait(mntr.signals_received == scrbrd.packets_evaluated);
        $display("Total mismatched packets %0d", scrbrd.packets_mismatched);
    endtask
endclass