! Written by A. C. Boley (updated 12 June 2007).
! See Pathria for questions.  This uses E = NkT^2 d ln Z / d T to calculate internal energies.
! However, the zero point energies are subtracted out (relevant for orthohydrogen
! and for the vibrational states).  The 16.78 in the metals
! term is from cameron 1968. This takes into account rotational states for 
! hydrogen and 1 vibrational state. zp is the parahydrogen partition function
! and dzpdt and ddzpdtt are its derivatives, *e for equilibrium, and *o for ortho.
      subroutine Initengtable()
        implicit none
        include 'hydroparam.h'
        include 'globals.h'
        include 'units.h'
        
        integer J,I
        
        real*8, parameter :: b = 85.4d0, vib = 5987.d0 ! see Draine et al. (1983)
        real*8 f1,f2,f3,f4,dummy0,dummy1

        real*8 zp(TTABLE),dzpdt(TTABLE)
        real*8 zo(TTABLE),dzodt(TTABLE)
        real*8 ze(TTABLE),dzedt(TTABLE)
        real*8 cvsm(TTABLE)


        do I = 1, TTABLE
          temptable(I) = dble(I-1)*5.d0 + tbgrnd ! for TTABLE = 400 takes to T = 1998
        enddo

        zp = 0.d0
        zo = 0.d0
        ze = 0.d0
        dzpdt = 0.d0
        dzodt = 0.d0
        dzedt = 0.d0

        do I = 1, TTABLE
         
          do J = 0, 24, 2 ! I found convergence with 24 terms.  You could use less if you want,
                          ! but why? If you are REALLY paranoid, you might increase the terms.

            f1 = dble(2*J+1)
            f2 = dble(J*(J+1))
            f3 = dble(2*(J+1)+1)
            f4 = dble((J+1)*(J+2))

            zp(I) = zp(I) +f1*exp(-f2*b/temptable(I))

            zo(I) = zo(I) +3.d0*f3*exp(-f4*b/temptable(I))

            dzpdt(I) = dzpdt(I) + f1*f2*b*exp(-f2*b/temptable(I))
     &               / temptable(I)**2 

            dzodt(I) = dzodt(I) + 3.d0*f3*f4*b
     &               * exp(-f4*b/temptable(I))
     &               / temptable(I)**2 

          enddo

            ze(I)  = zp(I) + zo(I)

            dzedt(I) = dzpdt(I) + dzodt(I) 

        enddo

        select case(H2STAT)

        case(0)

        do I = 1, TTABLE

          engtable(I) = bkmpcgs*0.5d0*temptable(I)*(1.5d0
     &                +
     &                  temptable(I)*dzpdt(I)/zp(I)
     &                +
     &                  vib/temptable(I)
     &                * (exp(-vib/temptable(I))
     &                / (1.d0-exp(-vib/temptable(I)))))


           engtable(I) = engtable(I)*xabun + (bkmpcgs*yabun*.25d0 +
     &                   bkmpcgs*zabun/16.78d0)*temptable(I)*1.5d0                 !from boss 1984 3.118d7 and 1.247d8
                                                              ! z based on mu_z = 16.78

        enddo

        case(1)

        do I = 1, TTABLE

          engtable(I) = bkmpcgs*0.5d0*temptable(I)*(1.5d0
     &                +
     &                 temptable(I)*(dzodt(I)/zo(I)
     &                - 2.d0*b/temptable(I)**2)
     &                +
     &                  vib/temptable(I)
     &                * (exp(-vib/temptable(I))
     &                / (1.d0-exp(-vib/temptable(I)))))


           engtable(I) = engtable(I)*xabun + (bkmpcgs*yabun*.25d0 +
     &                   bkmpcgs*zabun/16.78d0)*temptable(I)*1.5d0                 !from boss 1984 3.118d7 and 1.247d8
                                                              ! z based on mu_z = 16.78

        enddo

        case(2)

        do I = 1, TTABLE

          engtable(I) = bkmpcgs*0.5d0*temptable(I)*(1.5d0
     &                +
     &                  temptable(I)*dzpdt(I)/zp(I)
     &                * ac/(ac + bc)
     &                +
     &                  temptable(I)*(dzodt(I)/zo(I)
     &                - 2.d0*b/temptable(I)**2)
     &                * bc/(ac + bc)
     &                +
     &                  vib/temptable(I)
     &                * (exp(-vib/temptable(I))
     &                / (1.d0-exp(-vib/temptable(I)))))

           engtable(I) = engtable(I)*xabun + (bkmpcgs*yabun*.25d0 +
     &                   bkmpcgs*zabun/16.78d0)*temptable(I)*1.5d0                 !from boss 1984 3.118d7 and 1.247d8
                                                              ! z based on mu_z = 16.78

        enddo

        case(3)

        do I = 1, TTABLE

          engtable(I) = bkmpcgs*0.5d0*temptable(I)*(1.5d0
     &                +
     &                  temptable(I)*dzedt(I)/ze(I)
     &                + 
     &                  vib/temptable(I)
     &                * (exp(-vib/temptable(I))
     &                / (1.d0-exp(-vib/temptable(I)))))

           engtable(I) = engtable(I)*xabun + (bkmpcgs*yabun*.25d0 +
     &                   bkmpcgs*zabun/16.78d0)*temptable(I)*1.5d0                 !from boss 1984 3.118d7 and 1.247d8
                                                              ! z based on mu_z = 16.78

        enddo

        case(4)

        do I = 1, TTABLE

           engtable(I) = bkmpcgs*temptable(I)/(2.d0*(gamma-1.d0))

           engtable(I) = engtable(I)*xabun + (bkmpcgs*yabun*.25d0 +
     &                   bkmpcgs*zabun/16.78d0)*temptable(I)*1.5d0                 !from boss 1984 3.118d7 and 1.247d8
                                                              ! z based on mu_z = 16.78
 
        enddo

        end select


        muc = 1.d0 / (xabun*.5d0 + yabun*.25d0 + zabun/16.78d0)

        cvsm(1) = (engtable(1)-engtable(2))/(temptable(1)-temptable(2))
        cvsm(TTABLE) = (engtable(TTABLE)-engtable(TTABLE-1))
     &             / (temptable(TTABLE)-temptable(TTABLE-1))

        do I = 2, TTABLE-1
 
          cvsm(I) = (engtable(I-1)-engtable(I+1))
     &            / (temptable(I-1)-temptable(I+1))

        enddo

        do I = 1, TTABLE

          gammatable(I) = 1.d0 + bkmpcgs/(muc*cvsm(I))

        enddo

        open(unit=456,file="engtable.dat")
        do I = 1, TTABLE
         write(456, "(5(1X,1pe15.8))")temptable(I),
     &              1.+1./(cvsm(I)*muc/bkmpcgs),
     &              engtable(I)*muc/bkmpcgs,
     &              dzodt(I)/zo(I)*temptable(I)**2,
     &              gammatable(I)
        enddo
        close(456)


        print "(A,1pe10.3)","INITENGTABLE-> muc is ", muc
      
      return

      end subroutine Initengtable


