CC = chibicc
#CC = fcc
#CC = cc68
#CC = sdcc
MPU = 6800

ifeq ($(CC),chibicc)
AS = as6800
OBJS = crt0-c.o
CFLAGS = -I/opt/cc68/include
LD = ld6800
LIBC = /opt/chibicc/lib/libc.a
endif
ifeq ($(CC),fcc)
AS = as6800
OBJS = crt0-f.o memcpy-f.o memset-f.o ret-f.o
CFLAGS = -m$(MPU)
LD = ld6800
LIBC = /opt/fcc/lib/$(MPU)/lib$(MPU).a
endif
ifeq ($(CC),cc68)
AS = as68
OBJS = crt0.o
CFLAGS = -DSTDARG_REV -m$(MPU)
LD = ld68
LIBC = /opt/cc68/lib/lib$(MPU).a
endif

ifeq ($(CC),sdcc)
AS = sdas6800
OBJS = crt0-s.rel main.rel base.rel graph.rel util.rel
CFLAGS = -mmc6800 --opt-code-size
else
OBJS += main.o base.o graph.o util.o
endif
START = 4000

.SUFFIXES: .asm

all: a.bin

ifeq ($(CC),sdcc)
a.bin: $(OBJS)
	$(CC) -mmc6800 --no-std-crt0 --code-loc 0x$(START) --data-loc 0xd4 \
		--stack-loc 0xafff $(LDFLAGS) -o a.s19 $^
	objcopy -I srec -O binary a.s19 $@

%.rel: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

crt0-s.rel: crt0-s.s
	$(AS) -plosgff $@ $<
else
a.bin: $(OBJS)
	$(LD) -b -Z0xd4 -C 0x$(START) -m a.map $^ $(LIBC)
	dd if=a.out of=a.bin bs=`echo "ibase=16;$(START)"|bc` skip=1 >/dev/null 2>&1
	f9dasm -$(MPU) -offset $(START) a.bin > a.lst

.asm.o:
	$(AS) -l $(<:.asm=.lst) $<

.c.o:
	$(CC) $(CFLAGS) -S $<
	$(AS) -l $(<:.c=.lst) $(<:.c=.s)

endif

clean: SHELL = /bin/bash
clean:
	rm -f a.{bin,map,out,s19,lk,noi} *.{lst,o,rel,sym} {main,base,graph,util}.{s,asm}

main.o main.rel: types.h base.h graph.h
base.o base.rel: types.h base.h
graph.o graph.rel: types.h graph.h
util.o util.rel: types.h util.h
