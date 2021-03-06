#-*-Makefile-*-
# makefile for the 3-D astrophysical hydrodynamics code.

 #MAKEFILE = Makefile.intel

#===============================================================================
 TARCH      = -r8 -xHost -mcmodel=medium #-convert big_endian

 OMPF95     = mpif90

 F90FLAGS   = -O3 -pad -align all -nocheck -ipo -no-prec-div -shared-intel -openmp -fixed

 LIBS       = $(F90FLAGS) $(TARCH)

# C compilers
 CC         = icc

 .f.o:
	$(OMPF95) $(F90FLAGS) -c $*.f

 OBJ = fft_mpi.o dcomp_mpi.o blktri_mpi.o torqueout_mpi.o \
       boundary_mpi.o initengtable_mpi.o

#===============================================================================
#                        EXECUTABLES

decompose: dummy
	make target "FC=$(OMPF95)" "CC=$(CC)" \
 "CFLAGS=$(F90FLAGS) $(TARCH)" "TARGET = decompose_mpi"

#-------------------------------------------------------------------------------
target: $(OBJ) $(PERFOBJ) $(DBGOBJ)
	$(FC) $(LIBS) -o $(TARGET) $(OBJ)

dummy:

clean:
	rm -f *.o decompose_mpi


#===============================================================================
#                          OBJECTS

fft_mpi.o: fft_mpi.f
	$(FC) $(CFLAGS) -c $<

dcomp_mpi.o: dcomp_mpi.f
	$(FC) $(CFLAGS) -c dcomp_mpi.f

blktri_mpi.o: blktri_mpi.f
	$(FC) $(CFLAGS) -c $<

torqueout_mpi.o: torqueout_mpi.F
	$(FC) $(CFLAGS) -c $<

boundary_mpi.o: boundary_mpi.f
	$(FC) $(CFLAGS) -c $<

initengtable_mpi.o: initengtable_mpi.f
	$(FC) $(CFLAGS) -c $<
