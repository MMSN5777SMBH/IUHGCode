!-*-f90-*-     
      PROGRAM Ams
      IMPLICIT NONE

      INCLUDE 'mpif.h'
      
      INTEGER,PARAMETER :: DOUBLE = SELECTED_REAL_KIND(15,300)

      INTEGER :: jmax,kmax,lmax,start,finish,skip,size,jstart
      INTEGER :: jmax2,kmax2,mmax,amcount,process
      INTEGER :: count,j,k,l,m,i,m_return,sender,numargs
      INTEGER :: numranks,mpierr,myrank,mpiter,fill
      INTEGER :: status(MPI_STATUS_SIZE),package(2)
      REAL(DOUBLE),PARAMETER :: tconv = 1605.63
      REAL(DOUBLE),PARAMETER :: pi = 3.14159265358979323846d0
      REAL(DOUBLE),PARAMETER :: twopi = 2.d0*pi
      REAL(DOUBLE),DIMENSION(:,:,:),ALLOCATABLE    :: rho
      REAL(DOUBLE),DIMENSION(:,:),ALLOCATABLE      :: am,bm
      REAL(DOUBLE)           :: a0tot,tmpa
      REAL(DOUBLE),DIMENSION(:,:),ALLOCATABLE      :: avga,avgamid,a0
      REAL(DOUBLE),DIMENSION(:),ALLOCATABLE        :: timearr
      REAL(DOUBLE) :: time,phi,dphi
      LOGICAL EXISTSTAT
      CHARACTER outfile*80,indir*80
      CHARACTER rhofile*80,amfile*80,filenum*8,str*80
      CHARACTER jmaxin*10,kmaxin*10,lmaxin*10,startin*10,finishin*10
      CHARACTER jstartin*10,skipin*10

      type answer_return
         sequence
         REAL(DOUBLE) :: a, amid
      end type answer_return

      type (answer_return),ALLOCATABLE :: answers(:)

      numargs = IARGC()

      IF (numargs.ne.9) THEN
         print*,"Incorrect number of arguments"
         STOP
      ENDIF
      
      call getarg(1,jmaxin)
      call getarg(2,kmaxin)
      call getarg(3,lmaxin)
      call getarg(4,startin)
      call getarg(5,finishin)
      call getarg(6,skipin)
      call getarg(7,outfile)
      call getarg(8,jstartin)
      call getarg(9,indir)
      read(jmaxin,*)jmax
      read(kmaxin,*)kmax
      read(lmaxin,*)lmax
      read(startin,*)start
      read(finishin,*)finish
      read(skipin,*)skip
      read(jstartin,*)jstart

      call MPI_INIT(mpierr)
      call MPI_COMM_RANK(MPI_COMM_WORLD, myrank, mpierr)
      call MPI_COMM_SIZE(MPI_COMM_WORLD, numranks, mpierr)

      size = ((finish-start)/skip)+1
      mmax   = LMAX/2
      jmax2 = jmax+2
      kmax2 = kmax+2
      dphi  = twopi/lmax
      
      IF(mmax.ge.numranks-1) THEN
         mpiter = (mmax/(numranks-1))+1
         ALLOCATE(answers(mpiter))
      ELSE
         print*,"More MPI ranks than work, consider revising"
         STOP
      ENDIF
         
      ALLOCATE(rho(jmax2,kmax2,lmax))
 
      avga(:,:)          = 0.d0
      avgamid(:,:)       = 0.d0
      timearr(:)         = 0.d0
 
      IF(myrank.eq.0) THEN

         ALLOCATE(avga(LMAX/2,size))
         ALLOCATE(avgamid(LMAX/2,size))
         ALLOCATE(timearr(size))

         count = 0
         write(filenum,'(I6.6)')start
         rhofile=trim(indir)//'rho3d.'//filenum
         OPEN(UNIT=12,FILE=trim(rhofile),FORM='UNFORMATTED')

         READ(12) rho
         READ(12) time
         CLOSE(12)

         count = count+1
         timearr(count) = time/tconv

         DO i=start,finish,skip

            AMCOUNT = 1
            
            CALL MPI_BCAST(RHO,JMAX2*KMAX2*LMAX,MPI_DOUBLE_PRECISION,&
                 0,MPI_COMM_WORLD,mpierr)

            DO PROCESS=1,numranks-1
               package(2) = AMCOUNT*mpiter
               package(1) = package(2)-mpiter+1
               CALL MPI_SEND(package,2,MPI_INTEGER,PROCESS,AMCOUNT,&
                    MPI_COMM_WORLD,mpierr)
               AMCOUNT = AMCOUNT+1
               IF(package(2).ge.mmax)THEN
                  EXIT
               ENDIF
            ENDDO

911         CONTINUE

            IF(I.lt.finish) THEN
               WRITE(filenum,'(I6.6)')i+skip
               rhofile = trim(indir)//"rho3d."//filenum
         
               INQUIRE(FILE=trim(rhofile),EXIST=EXISTSTAT)
         
               IF(.not.EXISTSTAT) THEN
                  print*,"file ",rhofile, "does not exist"
                  STOP
!                  I = I+1
!                  GO TO 911
               ENDIF
         
         print*," AMS OUT -> OPENING FILE: ", rhofile
               OPEN(UNIT=12,FILE=trim(rhofile),FORM="UNFORMATTED")

               READ(12) rho
               READ(12) time
               CLOSE(12)
         
         print*,' AMS OUT -> READ FILE: ',rhofile
               count = count+1
               timearr(count) = time/tconv
            ENDIF

            DO PROCESS=1,AMCOUNT-1
               DO J = 1,mpiter
                  answers(J)%a = 0.d0
                  answers(J)%amid = 0.d0
               ENDDO

               call MPI_RECV(answers,2*mpiter,MPI_DOUBLE_PRECISION,&
                    MPI_ANY_SOURCE,MPI_ANY_TAG,MPI_COMM_WORLD,status,&
                    mpierr)
               
               sender = status(MPI_SOURCE)
               m_return = status(MPI_TAG)

               package(2) = m_return*mpiter
               package(1) = package(2)-mpiter+1

               fill = 1
               DO j=package(1),package(2)
                  avga(j,count-1) = answers(fill)%a
                  avgamid(j,count-1) = answers(fill)%amid
                  fill = fill + 1
               ENDDO
               
!!$               IF(AMCOUNT.le.MMAX) THEN
!!$                  call MPI_SEND(AMCOUNT,1,MPI_INTEGER,sender,AMCOUNT,&
!!$                       MPI_COMM_WORLD,mpierr)
!!$                  AMCOUNT = AMCOUNT+1
!!$               ELSE
!!$                  call MPI_SEND(MPI_BOTTOM,0,MPI_INTEGER,sender,MMAX+1,&
!!$                       MPI_COMM_WORLD,mpierr)
!!$               ENDIF
            ENDDO
         ENDDO

      ELSE
         do I=start,finish,skip
            CALL MPI_BCAST(RHO,JMAX2*KMAX2*LMAX,MPI_DOUBLE_PRECISION,&
                 0,MPI_COMM_WORLD,mpierr)

300         CALL MPI_RECV(package,2,MPI_INTEGER,0,MPI_ANY_TAG,&
                 MPI_COMM_WORLD,status,mpierr)
               
            ALLOCATE(a0(jmax2,kmax2))
            ALLOCATE(am(jmax2,kmax2))
            ALLOCATE(bm(jmax2,kmax2))
            fill = 1
            DO M = package(1),package(2)
            
               am(:,:)        = 0.d0
               bm(:,:)        = 0.d0
               a0(:,:)        = 0.d0
               a0tot          = 0.d0
               tmpa           = 0.d0

!$OMP PARALLEL DO DEFAULT(SHARED)&
!$OMP PRIVATE(phi,j,k) REDUCTION(+:am,bm,a0)&
!$OMP FIRSTPRIVATE(amcount)               
               DO l=1,lmax
                  phi = twopi*dble(l)/dble(lmax)
                  DO k=2,kmax+1
                     DO j=jstart,jmax+1
                        am(j,k) = am(j,k)+rho(j,k,l)*&
                             cos(m*phi)
                        bm(j,k) = bm(j,k)+rho(j,k,l)*&
                             sin(m*phi)
                        a0(j,k) = a0(j,k)+rho(j,k,l)
                     ENDDO
                  ENDDO
               ENDDO
!$OMP END PARALLEL DO

!$OMP PARALLEL DO DEFAULT(SHARED)&
!$OMP PRIVATE(k) REDUCTION(+:tmpa,a0tot)
               DO j=jstart,jmax+1
                  DO k=2,kmax+1
                     tmpa = tmpa+(sqrt((am(j,k))**2+&
                          (bm(j,k))**2)*(dble(J+1)**2-dble(J)**2))
                     a0tot = a0tot+a0(j,k)*(dble(J+1)**2-dble(J)**2)
                  ENDDO
               ENDDO
!$OMP END PARALLEL DO
               answers(fill)%a = tmpa*2.d0/a0tot
               tmpa = 0.d0
               a0tot = 0.d0
!$OMP PARALLEL DO DEFAULT(SHARED)&
!$OMP REDUCTION(+:tmpa,a0tot)
               DO j=jstart,jmax+1
                     tmpa = tmpa+(sqrt((am(j,2))**2+&
                          (bm(j,2))**2)*(dble(J+1)**2-dble(J)**2))
                     a0tot = a0tot+a0(j,2)*(dble(J+1)**2-dble(J)**2)
               ENDDO
!$OMP END PARALLEL DO               
                  
               answers(fill)%amid = tmpa*2.d0/a0tot
               fill = fill+1
            ENDDO

!                DO k=2,kmax+1
!                   DO j=jstart,jmax+1
!                      DO l=1,lmax
!                         phi = twopi*dble(l)/dble(lmax)        
!                         am(j,k) = am(j,k)+rho(j,k,l)*&
!                              cos(amcount*phi)
!                      bm(j,k) = bm(j,k)+rho(j,k,l)*&
!                           sin(amcount*phi)
!                      a0(j,k) = a0(j,k)+rho(j,k,l)
!                   ENDDO
!                   ambmslice(j,k) = sqrt((am(j,k))**2+
!      &                 (bm(j,k))**2)*(dble(J+1)**2-dble(J)**2)
!                   avgaslice(k) = avgaslice(k)
!      &                 +ambmslice(j,k)
!                   a0tot(m,count) = a0tot(m,count)+a0(j,k)
!      &                 *(dble(J+1)**2-dble(J)**2)
!                ENDDO
!                IF(K==2)THEN
!                   avgamid(m,count) = avgaslice(k)
!                   a0mid(m,count) = a0tot(m,count)
!                ENDIF
!                avga(m,count) = avga(m,count)+avgaslice(k)
!             ENDDO
            DEALLOCATE(a0)
            DEALLOCATE(am)
            DEALLOCATE(bm)
            
            AMCOUNT = status(MPI_TAG)
            CALL MPI_SEND(answers,2*mpiter,MPI_DOUBLE_PRECISION,0,AMCOUNT,&
                 MPI_COMM_WORLD,mpierr)
400      CONTINUE
      ENDDO
   ENDIF

!      print*,'FORTRAN COUNT = ',count

   IF(myrank.eq.0)THEN

      OPEN(UNIT=12,FILE=outfile,FORM='UNFORMATTED')
      WRITE(12) mmax,count
      WRITE(12) avga
      WRITE(12) avgamid
      WRITE(12) timearr
      CLOSE(12)
   ENDIF

   DEALLOCATE(rho)
   CALL MPI_FINALIZE(mpierr)
      
      
 END PROGRAM Ams

      
      
