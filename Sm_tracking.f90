!The Polymorphic Tracking Code
!Copyright (C) Etienne Forest and Frank Schmidt
! See file A_SCRATCH_SIZE.F90

MODULE S_TRACKING
  USE S_FAMILY

  IMPLICIT NONE
  logical(lp),TARGET :: ALWAYS_EXACT_PATCHING=.TRUE.
  type(fibre), pointer :: lost_fibre

  ! linked
  PRIVATE TRACK_LAYOUT_FLAG_R,TRACK_LAYOUT_FLAG_P,TRACK_LAYOUT_FLAG_S
  !  PRIVATE FIND_ORBIT_LAYOUT,FIND_ORBIT_M_LAYOUT,FIND_ENV_LAYOUT, FIND_ORBIT_LAYOUT_noda
  PRIVATE TRACK_LAYOUT_FLAG_R1,TRACK_LAYOUT_FLAG_P1,TRACK_LAYOUT_FLAG_S1
  PRIVATE MIS_FIBR,MIS_FIBP,MIS_FIBS
  PRIVATE TRACK_FIBRE_R,TRACK_FIBRE_P,TRACK_FIBRE_S
  PRIVATE TRACK_LAYOUT_FLAG_R1f,TRACK_LAYOUT_FLAG_P1f,TRACK_LAYOUT_FLAG_S1f
  PRIVATE TRACK_LAYOUT_FLAG_Rf,TRACK_LAYOUT_FLAG_Pf,TRACK_LAYOUT_FLAG_Sf

  ! TYPE UPDATING
  !    logical(lp) UPDATE
  ! END TYPE UPDATING



  !  TYPE (UPDATING), PARAMETER ::  COMPUTE= UPDATING(.TRUE.)
  LOGICAL :: COMPUTE = .FALSE.

  INTERFACE TRACK
     ! linked
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_R
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_P
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_S
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_R1
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_P1
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_S1
     MODULE PROCEDURE TRACK_FIBRE_R
     MODULE PROCEDURE TRACK_FIBRE_P
     MODULE PROCEDURE TRACK_FIBRE_S
  END INTERFACE

  INTERFACE TRACK_FLAG
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_R1f
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_P1f
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_S1f
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_Rf
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_Pf
     MODULE PROCEDURE TRACK_LAYOUT_FLAG_Sf
  END INTERFACE

  INTERFACE MIS_FIB
     MODULE PROCEDURE MIS_FIBR
     MODULE PROCEDURE MIS_FIBP
     MODULE PROCEDURE MIS_FIBS
  END INTERFACE


contains

  integer function TRACK_LAYOUT_FLAG_R1f(R,X,II1,k,X_IN)
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    real(dp), INTENT(INOUT):: X(6)
    TYPE(WORM), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1

    call track(R,X,II1,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_R1f)

  end  function TRACK_LAYOUT_FLAG_R1f

  integer function TRACK_LAYOUT_FLAG_P1f(R,X,II1,k,X_IN)
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    TYPE(REAL_8), INTENT(INOUT):: X(6)
    TYPE(WORM_8), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1

    call track(R,X,II1,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_P1f)

  end  function TRACK_LAYOUT_FLAG_P1f

  integer function TRACK_LAYOUT_FLAG_S1f(R,X,II1,k,X_IN)
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    TYPE(ENV_8), INTENT(INOUT):: X(6)
    TYPE(INNER_ENV_8_DATA), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1


    call track(R,X,II1,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_S1f)

  end  function TRACK_LAYOUT_FLAG_S1f

  SUBROUTINE TRACK_LAYOUT_FLAG_R1(R,X,II1,k,X_IN) ! Tracks real(dp) from II1 to the end or back to II1 if closed
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    real(dp), INTENT(INOUT):: X(6)
    TYPE(WORM), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1
    INTEGER II2

    CALL RESET_APERTURE_FLAG

    IF(R%CLOSED) THEN
       II2=II1+R%N
    ELSE
       II2=R%N+1
    ENDIF

    CALL TRACK(R,X,II1,II2,k,X_IN)
    if(c_%watch_user) ALLOW_TRACKING=.FALSE.
  END SUBROUTINE TRACK_LAYOUT_FLAG_R1

  SUBROUTINE TRACK_LAYOUT_FLAG_P1(R,X,II1,k,X_IN) ! Tracks polymorphs from II1 to the end or back to II1 if closed
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    TYPE(REAL_8), INTENT(INOUT):: X(6)
    TYPE(WORM_8), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1
    INTEGER II2

    CALL RESET_APERTURE_FLAG

    IF(R%CLOSED) THEN
       II2=II1+R%N
    ELSE
       II2=R%N+1
    ENDIF

    CALL TRACK(R,X,II1,II2,k,X_IN)
    if(c_%watch_user) ALLOW_TRACKING=.FALSE.

  END SUBROUTINE TRACK_LAYOUT_FLAG_P1

  SUBROUTINE TRACK_LAYOUT_FLAG_S1(R,X,II1,k,X_IN) ! Tracks envelope from II1 to the end or back to II1 if closed
    implicit none
    TYPE(layout),INTENT(INOUT):: R
    TYPE(ENV_8), INTENT(INOUT):: X(6)
    TYPE(INNER_ENV_8_DATA), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: II1
    INTEGER II2


    CALL RESET_APERTURE_FLAG

    IF(R%CLOSED) THEN
       II2=II1+R%N
    ELSE
       II2=R%N+1
    ENDIF

    CALL TRACK(R,X,II1,II2,k,X_IN)
    if(c_%watch_user) ALLOW_TRACKING=.FALSE.
  END SUBROUTINE TRACK_LAYOUT_FLAG_S1

  integer function TRACK_LAYOUT_FLAG_Rf(R,X,I1,I2,k,X_IN) ! Tracks double from i1 to i2 in state k
    IMPLICIT NONE
    TYPE(layout),INTENT(INOUT):: R
    real(dp), INTENT(INOUT):: X(6)
    TYPE(INTERNAL_STATE) K
    TYPE(WORM), OPTIONAL,INTENT(INOUT):: X_IN
    INTEGER, INTENT(IN):: I1,I2

    call track(R,X,I1,I2,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_Rf)

  end  function TRACK_LAYOUT_FLAG_Rf

  integer function TRACK_LAYOUT_FLAG_Pf(R,X,I1,I2,k,X_IN) ! Tracks double from i1 to i2 in state k
    IMPLICIT NONE
    TYPE(LAYOUT),INTENT(INOUT):: R ;TYPE(REAL_8), INTENT(INOUT):: X(6);
    INTEGER, INTENT(IN):: I1,I2; TYPE(INTERNAL_STATE) K;
    TYPE(WORM_8), OPTIONAL,INTENT(INOUT):: X_IN

    call track(R,X,I1,I2,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_Pf)

  end  function TRACK_LAYOUT_FLAG_Pf

  integer function TRACK_LAYOUT_FLAG_Sf(R,X,I1,I2,k,X_IN) ! Tracks double from i1 to i2 in state k
    IMPLICIT NONE
    TYPE(layout),INTENT(INOUT):: R
    TYPE(ENV_8), INTENT(INOUT):: X(6)
    TYPE(INNER_ENV_8_DATA), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: I1,I2

    call track(R,X,I1,I2,k,X_IN)
    call PRODUCE_APERTURE_FLAG(TRACK_LAYOUT_FLAG_Sf)

  end  function TRACK_LAYOUT_FLAG_Sf


  SUBROUTINE TRACK_LAYOUT_FLAG_R(R,X,I1,I2,k,X_IN) ! Tracks double from i1 to i2 in state k
    IMPLICIT NONE
    TYPE(layout),INTENT(INOUT):: R
    real(dp), INTENT(INOUT):: X(6)
    TYPE(INTERNAL_STATE) K
    TYPE(WORM), OPTIONAL,INTENT(INOUT):: X_IN
    INTEGER, INTENT(IN):: I1,I2
    INTEGER J
    TYPE (fibre), POINTER :: C


    CALL RESET_APERTURE_FLAG

    call move_to(r,c,MOD_N(I1,R%N))


    J=I1

    DO  WHILE(J<I2.AND.ASSOCIATED(C))

       CALL TRACK(C,X,K,R%CHARGE,X_IN)

       C=>C%NEXT
       J=J+1
    ENDDO

    if(c_%watch_user) ALLOW_TRACKING=.FALSE.

  END SUBROUTINE TRACK_LAYOUT_FLAG_R



  SUBROUTINE TRACK_LAYOUT_FLAG_P(R,X,I1,I2,K,X_IN) ! TRACKS POLYMORPHS FROM I1 TO I2 IN STATE K
    IMPLICIT NONE
    TYPE(LAYOUT),INTENT(INOUT):: R ;TYPE(REAL_8), INTENT(INOUT):: X(6);
    INTEGER, INTENT(IN):: I1,I2; TYPE(INTERNAL_STATE) K;
    TYPE(WORM_8), OPTIONAL,INTENT(INOUT):: X_IN
    INTEGER J;

    TYPE (FIBRE), POINTER :: C


    CALL RESET_APERTURE_FLAG

    CALL MOVE_TO(R,C,MOD_N(I1,R%N))


    J=I1

    DO  WHILE(J<I2.AND.ASSOCIATED(C))

       CALL TRACK(C,X,K,R%CHARGE,X_IN)

       C=>C%NEXT
       J=J+1
    ENDDO

    if(c_%watch_user) ALLOW_TRACKING=.FALSE.

    ! PATCHES
  END SUBROUTINE TRACK_LAYOUT_FLAG_P

  SUBROUTINE TRACK_LAYOUT_FLAG_S(R,X,I1,I2,k,X_IN) ! Tracks envelopes from i1 to i2 in state k
    IMPLICIT NONE
    TYPE(layout),INTENT(INOUT):: R
    TYPE(ENV_8), INTENT(INOUT):: X(6)
    TYPE(INNER_ENV_8_DATA), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(INTERNAL_STATE) K
    INTEGER, INTENT(IN):: I1,I2
    INTEGER I,J,M,N
    ! YS SPECIFIC STUFF
    TYPE(DAMAP) ID,XT,DISP
    TYPE(REAL_8) XR(6),X1,X3
    real(dp) V(6)
    TYPE (fibre), POINTER :: C



    CALL RESET_APERTURE_FLAG

    ! new stuff with kind=3
    IF(k%para_in ) knob=.true.
    ! end new stuff with kind=3


    call move_to(r,c,MOD_N(I1,R%N))


    J=I1

    DO  WHILE(J<I2.AND.ASSOCIATED(C))
       CALL TRACK(C,X,K,R%CHARGE,X_IN)  !

       C=>C%NEXT
       J=J+1
    ENDDO
    ! new stuff with kind=3
    knob=.FALSE.
    ! end new stuff with kind=3

    ! Radiation

    CALL ALLOC(ID);CALL ALLOC(XT);CALL ALLOC(DISP);
    CALL ALLOC(X1,X3);CALL ALLOC(XR);
    xr=x
    v=xr
    id=0
    XT=XR
    DISP=XT*ID
    ID=1
    DISP=ID-DISP
    XT=DISP*XT

    xr=xt+v


    do i=1,6
       do j=1,6
          X(I)%SIGMAf(J)=zero
       enddo
    enddo

    do i=1,6
       do j=1,6
          DO M=1,6
             DO N=1,6
                X1=(xr(I)).par.ind_stoc(M)
                X3=(xr(j)).par.ind_stoc(n)
                X(I)%SIGMAf(J)=X(m)%E(n)*x1*x3+X(I)%SIGMAf(J)
                X(I)%SIGMAf(J)=X(m)%SIGMA0(n)*x1*x3+X(I)%SIGMAf(J)
             enddo
          enddo
       enddo
    enddo

    CALL KILL(XT);CALL KILL(DISP);
    CALL KILL(X1,X3);CALL KILL(XR);

    if(c_%watch_user) ALLOW_TRACKING=.FALSE.
  END SUBROUTINE TRACK_LAYOUT_FLAG_S


  SUBROUTINE TRACK_FIBRE_R(C,X,K,CHARGE,X_IN)
    implicit none
    logical(lp) :: doneitt=.true.
    logical(lp) :: doneitf=.false.
    TYPE(FIBRE),TARGET,INTENT(INOUT):: C
    real(dp), INTENT(INOUT):: X(6)
    TYPE(WORM), OPTIONAL,INTENT(INOUT):: X_IN
    INTEGER,optional, target, INTENT(IN) :: CHARGE
    TYPE(INTERNAL_STATE), INTENT(IN) :: K
    logical(lp) ou,patch,PATCHT,PATCHG,PATCHE
    TYPE (fibre), POINTER :: CN
    real(dp), POINTER :: P0,B0
    REAL(DP) ENT(3,3), A(3)
    integer,target :: charge1
    IF(.NOT.CHECK_STABLE) return

    IF(PRESENT(X_IN)) then
       X_IN%F=>c ; X_IN%E%F=>C; X_IN%NST=>X_IN%E%NST;
    endif


    ! DIRECTIONAL VARIABLE
    C%MAG%P%DIR=>C%DIR
    if(present(charge)) then
     C%MAG%P%CHARGE=>CHARGE
    else
     charge1=1
     C%MAG%P%CHARGE=>CHARGE1
    endif
    !
    !    IF(.NOT.CHECK_STABLE) CHECK_STABLE=.TRUE.
    C%MAG=K
    !FRONTAL PATCH
    IF(ASSOCIATED(C%PATCH)) THEN
       PATCHT=C%PATCH%TIME ;PATCHE=C%PATCH%ENERGY ;PATCHG=C%PATCH%PATCH;
    ELSE
       PATCHT=.FALSE. ; PATCHE=.FALSE. ;PATCHG=.FALSE.;
    ENDIF
    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,-6)
       X_IN%POS(1)=X_IN%nst
    endif

    IF(PATCHE) THEN
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%PREVIOUS
       IF(ASSOCIATED(CN)) THEN ! ASSOCIATED
          IF(.NOT.CN%PATCH%ENERGY) THEN     ! No need to patch IF PATCHED BEFORE
             P0=>CN%MAG%P%P0C
             B0=>CN%MAG%P%BETA0

             X(2)=X(2)*P0/C%MAG%P%P0C
             X(4)=X(4)*P0/C%MAG%P%P0C
             IF(C%MAG%P%TIME)THEN
                X(5)=SQRT(one+two*X(5)/B0+X(5)**2)  !X(5) = 1+DP/P0C_OLD
                X(5)=X(5)*P0/C%MAG%P%P0C-one !X(5) = DP/P0C_NEW
                X(5)=(two*X(5)+X(5)**2)/(SQRT(one/C%MAG%P%BETA0**2+two*X(5)+X(5)**2)+one/C%MAG%P%BETA0)
             ELSE
                X(5)=(one+X(5))*P0/C%MAG%P%P0C-one
             ENDIF
          ENDIF ! No need to patch
       ENDIF ! ASSOCIATED

    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-5)

    ! The chart frame of reference is located here implicitely
    IF(PATCHG) THEN
       patch=ALWAYS_EXACT_PATCHING.or.C%MAG%P%EXACT
       X(3)=C%PATCH%A_XZ*X(3);X(4)=C%PATCH%A_YZ*X(4);
       CALL ROT_YZ(C%PATCH%A_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       X(1)=C%PATCH%A_XZ*X(1);X(2)=C%PATCH%A_XZ*X(2);
       CALL ROT_XZ(C%PATCH%A_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%A_ANG(3),X,PATCH)
       CALL TRANS(C%PATCH%A_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-4)
    IF(PATCHT) THEN
       X(6)=X(6)-C%PATCH%a_T
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-3)

    CALL DTILTD(C%DIR,C%MAG%P%TILTD,1,X)
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-2)
    ! The magnet frame of reference is located here implicitely before misalignments

    !      CALL TRACK(C,X,EXACTMIS=K%EXACTMIS)
    IF(C%MAG%MIS) THEN
       ou = K%EXACTMIS.or.C%MAG%EXACTMIS
       CALL MIS_FIB(C,X,OU,DONEITT)
    ENDIF
    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,-1)
       X_IN%POS(2)=X_IN%nst
    endif

    CALL TRACK(C%MAG,X,X_IN)

    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,X_IN%nst+1)
       X_IN%POS(3)=X_IN%nst
    endif

    IF(C%MAG%MIS) THEN
       CALL MIS_FIB(C,X,OU,DONEITF)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)
    ! The magnet frame of reference is located here implicitely before misalignments
    CALL DTILTD(C%DIR,C%MAG%P%TILTD,2,X)
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(PATCHT) THEN
       X(6)=X(6)-C%PATCH%b_T
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(PATCHG) THEN
       X(3)=C%PATCH%B_YZ*X(3);X(4)=C%PATCH%B_YZ*X(4);
       CALL ROT_YZ(C%PATCH%B_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       X(1)=C%PATCH%B_XZ*X(1);X(2)=C%PATCH%B_XZ*X(2);
       CALL ROT_XZ(C%PATCH%B_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%B_ANG(3),X,DONEITT)
       CALL TRANS(C%PATCH%B_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    ! The CHART frame of reference is located here implicitely

    IF(PATCHE) THEN
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%NEXT
       IF(.NOT.ASSOCIATED(CN)) CN=>C
       P0=>CN%MAG%P%P0C
       B0=>CN%MAG%P%BETA0
       X(2)=X(2)*C%MAG%P%P0C/P0
       X(4)=X(4)*C%MAG%P%P0C/P0
       IF(C%MAG%P%TIME)THEN
          X(5)=SQRT(one+two*X(5)/C%MAG%P%BETA0+X(5)**2)  !X(5) = 1+DP/P0C_OLD
          X(5)=X(5)*C%MAG%P%P0C/P0-one !X(5) = DP/P0C_NEW
          X(5)=(two*X(5)+X(5)**2)/(SQRT(one/B0**2+two*X(5)+X(5)**2)+one/B0)
       ELSE
          X(5)=(one+X(5))*C%MAG%P%P0C/P0-one
       ENDIF
    ENDIF

    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,X_IN%nst+1)
       X_IN%POS(4)=X_IN%nst
    endif

    IF(PRESENT(X_IN))  THEN
       CALL GFRAME(X_IN%E,ENT,A,-7)
       CALL  SURVEY(C,ENT,A,E_IN=X_IN%E)
    ENDIF

    C%MAG=DEFAULT
    nullify(C%MAG%P%DIR)
    nullify(C%MAG%P%CHARGE)
    if(abs(x(1))+abs(x(3))>absolute_aperture.or.(.not.CHECK_MADX_APERTURE)) then
       if(CHECK_MADX_APERTURE) c_%message="exceed absolute_aperture in TRACK_FIBRE_R"
       CHECK_STABLE=.false.
       lost_fibre=>c
    endif

  END SUBROUTINE TRACK_FIBRE_R

  SUBROUTINE TRACK_FIBRE_P(C,X,K,CHARGE,X_IN)
    IMPLICIT NONE
    logical(lp) :: doneitt=.true.
    logical(lp) :: doneitf=.false.
    TYPE(FIBRE),TARGET,INTENT(INOUT):: C
    TYPE(REAL_8), INTENT(INOUT):: X(6)
    TYPE(WORM_8), OPTIONAL,INTENT(INOUT):: X_IN
    INTEGER, optional,TARGET, INTENT(IN) :: CHARGE
    TYPE(INTERNAL_STATE), INTENT(IN) :: K
    logical(lp) OU,PATCH,PATCHT,PATCHG,PATCHE
    TYPE (FIBRE), POINTER :: CN
    REAL(DP), POINTER :: P0,B0
    REAL(DP) ENT(3,3), A(3)
    integer,target :: charge1

    IF(.NOT.CHECK_STABLE) return

    IF(PRESENT(X_IN)) then
       X_IN%F=>c ; X_IN%E%F=>C; X_IN%NST=>X_IN%E%NST;
    endif

    ! NEW STUFF WITH KIND=3: KNOB OF FPP IS SET TO TRUE IF NECESSARY
    IF(K%PARA_IN ) KNOB=.TRUE.
    ! END NEW STUFF WITH KIND=3

    ! DIRECTIONAL VARIABLE AND CHARGE IS PASSED TO THE ELEMENT
    C%MAGP%P%DIR=>C%DIR
    if(present(charge)) then
     C%MAGP%P%CHARGE=>CHARGE
    else
     charge1=1
     C%MAGP%P%CHARGE=>CHARGE1
    endif
    !

    ! PASSING THE STATE K TO THE ELEMENT
    C%MAGP=K
    !FRONTAL PATCH
    IF(ASSOCIATED(C%PATCH)) THEN
       PATCHT=C%PATCH%TIME ;PATCHE=C%PATCH%ENERGY ;PATCHG=C%PATCH%PATCH;
    ELSE
       PATCHT=.FALSE. ; PATCHE=.FALSE. ;PATCHG=.FALSE.;
    ENDIF
    ! ENERGY PATCH
    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,-6)
       X_IN%POS(1)=X_IN%nst
    endif
    IF(PATCHE) THEN
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%PREVIOUS
       IF(ASSOCIATED(CN)) THEN ! ASSOCIATED
          IF(.NOT.CN%PATCH%ENERGY) THEN     ! NO NEED TO PATCH IF PATCHED BEFORE
             P0=>CN%MAGP%P%P0C
             B0=>CN%MAGP%P%BETA0

             X(2)=X(2)*P0/C%MAGP%P%P0C
             X(4)=X(4)*P0/C%MAGP%P%P0C
             IF(C%MAGP%P%TIME)THEN
                X(5)=SQRT(ONE+TWO*X(5)/B0+X(5)**2)  !X(5) = 1+DP/P0C_OLD
                X(5)=X(5)*P0/C%MAGP%P%P0C-ONE !X(5) = DP/P0C_NEW
                X(5)=(TWO*X(5)+X(5)**2)/(SQRT(ONE/C%MAGP%P%BETA0**2+TWO*X(5)+X(5)**2)+ONE/C%MAGP%P%BETA0)
             ELSE
                X(5)=(ONE+X(5))*P0/C%MAGP%P%P0C-ONE
             ENDIF
          ENDIF ! NO NEED TO PATCH
       ENDIF ! ASSOCIATED

    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-5)


    ! POSITION PATCH
    IF(PATCHG) THEN
       patch=ALWAYS_EXACT_PATCHING.or.C%MAG%P%EXACT
       X(3)=C%PATCH%A_XZ*X(3);X(4)=C%PATCH%A_YZ*X(4);
       CALL ROT_YZ(C%PATCH%A_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       X(1)=C%PATCH%A_XZ*X(1);X(2)=C%PATCH%A_XZ*X(2);
       CALL ROT_XZ(C%PATCH%A_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%A_ANG(3),X,PATCH)
       CALL TRANS(C%PATCH%A_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-4)
    ! TIME PATCH
    IF(PATCHT) THEN
       X(6)=X(6)-C%PATCH%A_T
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-3)

    CALL DTILTD(C%DIR,C%MAGP%P%TILTD,1,X)
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-2)
    ! MISALIGNMENTS AT THE ENTRANCE
    IF(C%MAGP%MIS) THEN
       OU = K%EXACTMIS.OR.C%MAGP%EXACTMIS
       CALL MIS_FIB(C,X,OU,DONEITT)
    ENDIF
    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,-1)
       X_IN%POS(2)=X_IN%nst
    endif
    ! ************************************************************************
    !  THE ACTUAL MAGNET PROPAGATOR AS IT WOULD APPEAR IN A STANDARD CODE

    CALL TRACK(C%MAGP,X,X_IN)
    !
    ! ************************************************************************
    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,X_IN%nst+1)
       X_IN%POS(3)=X_IN%nst
    endif


    ! MISALIGNMENTS AT THE EXIT
    IF(C%MAGP%MIS) THEN
       CALL MIS_FIB(C,X,OU,DONEITF)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    CALL DTILTD(C%DIR,C%MAGP%P%TILTD,2,X)
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    !EXIT PATCH
    ! TIME PATCH
    IF(PATCHT) THEN
       X(6)=X(6)-C%PATCH%B_T
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    ! POSITION PATCH
    IF(PATCHG) THEN
       X(3)=C%PATCH%B_YZ*X(3);X(4)=C%PATCH%B_YZ*X(4);
       CALL ROT_YZ(C%PATCH%B_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       X(1)=C%PATCH%B_XZ*X(1);X(2)=C%PATCH%B_XZ*X(2);
       CALL ROT_XZ(C%PATCH%B_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%B_ANG(3),X,DONEITT)
       CALL TRANS(C%PATCH%B_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
    ENDIF
    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    ! ENERGY PATCH
    IF(PATCHE) THEN
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%NEXT
       IF(.NOT.ASSOCIATED(CN)) CN=>C
       P0=>CN%MAGP%P%P0C
       B0=>CN%MAGP%P%BETA0
       X(2)=X(2)*C%MAGP%P%P0C/P0
       X(4)=X(4)*C%MAGP%P%P0C/P0
       IF(C%MAGP%P%TIME)THEN
          X(5)=SQRT(ONE+TWO*X(5)/C%MAGP%P%BETA0+X(5)**2)  !X(5) = 1+DP/P0C_OLD
          X(5)=X(5)*C%MAGP%P%P0C/P0-ONE !X(5) = DP/P0C_NEW
          X(5)=(TWO*X(5)+X(5)**2)/(SQRT(ONE/B0**2+TWO*X(5)+X(5)**2)+ONE/B0)
       ELSE
          X(5)=(ONE+X(5))*C%MAGP%P%P0C/P0-ONE
       ENDIF
    ENDIF

    IF(PRESENT(X_IN)) then
       CALL XMID(X_IN,X,X_IN%nst+1)
       X_IN%POS(4)=X_IN%nst
    endif

    IF(PRESENT(X_IN))  THEN
       CALL GFRAME(X_IN%E,ENT,A,-7)
       CALL  SURVEY(C,ENT,A,E_IN=X_IN%E)
    ENDIF



    ! ELEMENT IS RESTAURED TO THE DEFAULT STATE
    C%MAGP=DEFAULT
    ! DIRECTIONAL VARIABLE AND CHARGE ARE ELIMINATED
    NULLIFY(C%MAGP%P%DIR)
    NULLIFY(C%MAGP%P%CHARGE)


    ! KNOB IS RETURNED TO THE PTC DEFAULT
    ! NEW STUFF WITH KIND=3
    KNOB=.FALSE.
    ! END NEW STUFF WITH KIND=3

    if(abs(x(1))+abs(x(3))>absolute_aperture.or.(.not.CHECK_MADX_APERTURE)) then
       if(CHECK_MADX_APERTURE) c_%message="exceed absolute_aperture in TRACK_FIBRE_P"
       CHECK_STABLE=.false.
       lost_fibre=>c
    endif

  END SUBROUTINE TRACK_FIBRE_P


  SUBROUTINE TRACK_FIBRE_S(C,X,K,CHARGE,X_IN)   !,UPDATE
    implicit none
    logical(lp) :: doneitt=.true.
    logical(lp) :: doneitf=.false.
    TYPE(FIBRE),TARGET,INTENT(INOUT):: C
    TYPE(ENV_8), INTENT(INOUT):: X(6)
    TYPE(INNER_ENV_8_DATA), OPTIONAL,INTENT(INOUT):: X_IN
    TYPE(REAL_8)  Y(6)
    INTEGER, optional,target, INTENT(IN) :: CHARGE
    TYPE(INTERNAL_STATE), INTENT(IN) :: K
    logical(lp) ou,patch,PATCHT,PATCHG,PATCHE
    !    TYPE(UPDATING), optional,intent(in):: UPDATE
    TYPE (fibre), POINTER :: CN
    real(dp), POINTER :: P0,B0
    ! YS SPECIFIC STUFF
    TYPE(DAMAP) ID,XT,DISP
    TYPE(REAL_8) XR(6),X1,X3
    real(dp) V(6)
    INTEGER I,J,M,N
    integer,target :: charge1

    IF(.NOT.CHECK_STABLE) return

    ! new stuff with kind=3
    IF(k%para_in ) knob=.true.
    ! end new stuff with kind=3

    ! DIRECTIONAL VARIABLE
    C%MAGP%P%DIR=>C%DIR
    if(present(charge)) then
     C%MAGP%P%CHARGE=>CHARGE
    else
     charge1=1
     C%MAGP%P%CHARGE=>CHARGE1
    endif
    !

    C%MAGP=K
    !FRONTAL PATCH
    IF(ASSOCIATED(C%PATCH)) THEN
       PATCHT=C%PATCH%TIME ;PATCHE=C%PATCH%ENERGY ;PATCHG=C%PATCH%PATCH;
    ELSE
       PATCHT=.FALSE. ; PATCHE=.FALSE. ;PATCHG=.FALSE.;
    ENDIF


    !   IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-6)

    IF(PATCHE) THEN
       CALL ALLOC(Y)
       Y=X
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%PREVIOUS
       IF(ASSOCIATED(CN)) THEN ! ASSOCIATED
          IF(.NOT.CN%PATCH%ENERGY) THEN   ! No need to patch IF PATCHED BEFORE
             P0=>CN%MAG%P%P0C
             B0=>CN%MAG%P%BETA0

             Y(2)=Y(2)*P0/C%MAGP%P%P0C
             Y(4)=Y(4)*P0/C%MAGP%P%P0C
             IF(C%MAGP%P%TIME)THEN
                Y(5)=SQRT(one+two*Y(5)/B0+Y(5)**2)  !Y(5) = 1+DP/P0C_OLD
                Y(5)=Y(5)*P0/C%MAGP%P%P0C-one !Y(5) = DP/P0C_NEW
                Y(5)=(two*Y(5)+Y(5)**2)/(SQRT(one/C%MAGP%P%BETA0**2+two*Y(5)+Y(5)**2)+one/C%MAGP%P%BETA0)
             ELSE
                Y(5)=(one+Y(5))*P0/C%MAGP%P%P0C-one
             ENDIF
          ENDIF ! No need to patch
       ENDIF ! ASSOCIATED

       X=Y
       CALL KILL(Y)
    ENDIF
    !       IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-5)






    IF(PATCHG) THEN
       CALL ALLOC(Y)
       patch=ALWAYS_EXACT_PATCHING.or.C%MAG%P%EXACT
       Y=X
       Y(3)=C%PATCH%A_YZ*Y(3);Y(4)=C%PATCH%A_YZ*Y(4);
       X=Y
       CALL ROT_YZ(C%PATCH%A_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       Y=X
       Y(1)=C%PATCH%A_XZ*Y(1);Y(2)=C%PATCH%A_XZ*Y(2);
       X=Y
       CALL ROT_XZ(C%PATCH%A_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%A_ANG(3),X,PATCH)
       CALL TRANS(C%PATCH%A_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL KILL(Y)
    ENDIF
    !       IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-4)


    IF(PATCHT) THEN      ! PATCHE BEFORE! 2003.9.18 BUG
       CALL ALLOC(Y)
       Y=X
       Y(6)=Y(6)-C%PATCH%a_T
       X=Y
       CALL KILL(Y)
    ENDIF

    !       IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-3)


    CALL DTILTD(C%DIR,C%MAGP%P%TILTD,1,X)
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-2)

    IF(C%MAGP%MIS) THEN
       ou = K%EXACTMIS.or.C%MAGP%EXACTMIS
       CALL MIS_FIB(C,X,OU,DONEITT)
    ENDIF
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,-1)

    CALL TRACK(C%MAGP,X,X_IN)

    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(C%MAGP%MIS) THEN
       CALL MIS_FIB(C,X,OU,DONEITF)
    ENDIF
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    CALL DTILTD(C%DIR,C%MAGP%P%TILTD,2,X)
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(PATCHT) THEN  ! PATCHE BEFORE! 2003.9.18  bug
       CALL ALLOC(Y)
       Y=X
       Y(6)=Y(6)-C%PATCH%b_T
       X=Y
       CALL KILL(Y)
    ENDIF
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(PATCHG) THEN
       CALL ALLOC(Y)
       Y=X
       Y(3)=C%PATCH%B_YZ*Y(3);Y(4)=C%PATCH%B_YZ*Y(4);
       X=Y
       CALL ROT_YZ(C%PATCH%B_ANG(1),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       Y=X
       Y(1)=C%PATCH%B_XZ*Y(1);Y(2)=C%PATCH%B_XZ*Y(2);
       X=Y
       CALL ROT_XZ(C%PATCH%B_ANG(2),X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL ROT_XY(C%PATCH%B_ANG(3),X,DONEITT)
       CALL TRANS(C%PATCH%B_D,X,C%MAG%P%BETA0,PATCH,C%MAG%P%TIME)
       CALL KILL(Y)
    ENDIF
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

    IF(PATCHE) THEN
       CALL ALLOC(Y)
       Y=X
       NULLIFY(P0);NULLIFY(B0);
       CN=>C%NEXT
       IF(.NOT.ASSOCIATED(CN)) CN=>C
       P0=>CN%MAGP%P%P0C
       B0=>CN%MAGP%P%BETA0
       Y(2)=Y(2)*C%MAGP%P%P0C/P0
       Y(4)=Y(4)*C%MAGP%P%P0C/P0
       IF(C%MAGP%P%TIME)THEN
          Y(5)=SQRT(one+two*Y(5)/C%MAGP%P%BETA0+Y(5)**2)  !Y(5) = 1+DP/P0C_OLD
          Y(5)=Y(5)*C%MAGP%P%P0C/P0-one !Y(5) = DP/P0C_NEW
          Y(5)=(two*Y(5)+Y(5)**2)/(SQRT(one/B0**2+two*Y(5)+Y(5)**2)+one/B0)
       ELSE
          Y(5)=(one+Y(5))*C%MAGP%P%P0C/P0-one
       ENDIF
       X=Y
       CALL KILL(Y)
    ENDIF


    nullify(C%MAGP%P%DIR)
    nullify(C%MAGP%P%CHARGE)
    C%MAGP=DEFAULT


    if(abs(x(1)%v)+abs(x(3)%v)>absolute_aperture.or.(.not.CHECK_MADX_APERTURE)) then
       if(CHECK_MADX_APERTURE) c_%message="exceed absolute_aperture in TRACK_FIBRE_S"
       CHECK_STABLE=.false.
       lost_fibre=>c
    endif

    ! new stuff with kind=3
    knob=.FALSE.
    ! end new stuff with kind=3
    if(COMPUTE) then
       ! Radiation

       CALL ALLOC(ID);CALL ALLOC(XT);CALL ALLOC(DISP);
       CALL ALLOC(X1,X3);CALL ALLOC(XR);
       xr=x
       v=xr
       id=0
       XT=XR
       DISP=XT*ID
       ID=1
       DISP=ID-DISP
       XT=DISP*XT

       xr=xt+v


       do i=1,6
          do j=1,6
             X(I)%SIGMAf(J)=zero
          enddo
       enddo

       do i=1,6
          do j=1,6
             DO M=1,6
                DO N=1,6
                   X1=(xr(I)).par.ind_stoc(M)
                   X3=(xr(j)).par.ind_stoc(n)
                   X(I)%SIGMAf(J)=X(m)%E(n)*x1*x3+X(I)%SIGMAf(J)
                   X(I)%SIGMAf(J)=X(m)%SIGMA0(n)*x1*x3+X(I)%SIGMAf(J)
                enddo
             enddo
          enddo
       enddo

       CALL KILL(XT);CALL KILL(DISP);
       CALL KILL(X1,X3);CALL KILL(XR);

    endif
    !    IF(PRESENT(X_IN)) CALL XMID(X_IN,X,X_IN%nst+1)

  END SUBROUTINE TRACK_FIBRE_S





  !   Misalignment routines
  SUBROUTINE MIS_FIBR(C,X,OU,ENTERING)
    implicit none
    ! MISALIGNS REAL FIBRES IN PTC ORDER FOR FORWARD AND BACKWARD FIBRES
    TYPE(FIBRE),INTENT(INOUT):: C
    real(dp), INTENT(INOUT):: X(6)
    logical(lp),INTENT(IN):: OU,ENTERING

    IF(ASSOCIATED(C%CHART)) THEN
       IF(C%DIR==1) THEN   ! FORWARD PROPAGATION
          IF(ENTERING) THEN
             CALL ROT_YZ(C%CHART%ANG_IN(1),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)   ! ROTATIONS
             CALL ROT_XZ(C%CHART%ANG_IN(2),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)
             CALL ROT_XY(C%CHART%ANG_IN(3),X,OU)
             CALL TRANS(C%CHART%D_IN,X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)         ! TRANSLATION
          ELSE
             CALL ROT_YZ(C%CHART%ANG_OUT(1),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)  ! ROTATIONS
             CALL ROT_XZ(C%CHART%ANG_OUT(2),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)
             CALL ROT_XY(C%CHART%ANG_OUT(3),X,OU)
             CALL TRANS(C%CHART%D_OUT,X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)        ! TRANSLATION
          ENDIF
       ELSE
          IF(ENTERING) THEN  ! BACKWARD PROPAGATION
             C%CHART%D_OUT(1)=-C%CHART%D_OUT(1)
             C%CHART%D_OUT(2)=-C%CHART%D_OUT(2)
             C%CHART%ANG_OUT(3)=-C%CHART%ANG_OUT(3)
             CALL TRANS(C%CHART%D_OUT,X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)        ! TRANSLATION
             CALL ROT_XY(C%CHART%ANG_OUT(3),X,OU)
             CALL ROT_XZ(C%CHART%ANG_OUT(2),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)
             CALL ROT_YZ(C%CHART%ANG_OUT(1),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)  ! ROTATIONS
             C%CHART%D_OUT(1)=-C%CHART%D_OUT(1)
             C%CHART%D_OUT(2)=-C%CHART%D_OUT(2)
             C%CHART%ANG_OUT(3)=-C%CHART%ANG_OUT(3)
          ELSE
             C%CHART%D_IN(1)=-C%CHART%D_IN(1)
             C%CHART%D_IN(2)=-C%CHART%D_IN(2)
             C%CHART%ANG_IN(3)=-C%CHART%ANG_IN(3)
             CALL TRANS(C%CHART%D_IN,X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)         ! TRANSLATION
             CALL ROT_XY(C%CHART%ANG_IN(3),X,OU)
             CALL ROT_XZ(C%CHART%ANG_IN(2),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)
             CALL ROT_YZ(C%CHART%ANG_IN(1),X,C%MAG%P%BETA0,OU,C%MAG%P%TIME)   ! ROTATIONS
             C%CHART%D_IN(1)=-C%CHART%D_IN(1)
             C%CHART%D_IN(2)=-C%CHART%D_IN(2)
             C%CHART%ANG_IN(3)=-C%CHART%ANG_IN(3)
          ENDIF
       ENDIF
    ENDIF
  END SUBROUTINE MIS_FIBR

  SUBROUTINE MIS_FIBP(C,X,OU,ENTERING)  ! Misaligns polymorphic fibres in PTC order for forward and backward fibres
    implicit none
    TYPE(FIBRE),INTENT(INOUT):: C
    type(REAL_8), INTENT(INOUT):: X(6)
    logical(lp),INTENT(IN):: OU,ENTERING

    IF(ASSOCIATED(C%CHART)) THEN
       IF(C%DIR==1) THEN
          IF(ENTERING) THEN
             CALL ROT_YZ(C%CHART%ang_in(1),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                ! rotations
             CALL ROT_XZ(C%CHART%ang_in(2),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)
             CALL ROT_XY(C%CHART%ang_in(3),X,OU)
             CALL TRANS(C%CHART%d_in,X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                       !translation
          ELSE
             CALL ROT_YZ(C%CHART%ang_out(1),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                ! rotations
             CALL ROT_XZ(C%CHART%ang_out(2),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)
             CALL ROT_XY(C%CHART%ang_out(3),X,OU)
             CALL TRANS(C%CHART%d_out,X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                       !translation
          ENDIF
       ELSE
          IF(ENTERING) THEN
             C%CHART%d_out(1)=-C%CHART%d_out(1)
             C%CHART%d_out(2)=-C%CHART%d_out(2)
             C%CHART%ang_out(3)=-C%CHART%ang_out(3)
             CALL TRANS(C%CHART%d_out,X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                       !translation
             CALL ROT_XY(C%CHART%ang_out(3),X,OU)
             CALL ROT_XZ(C%CHART%ang_out(2),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)
             CALL ROT_YZ(C%CHART%ang_out(1),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                ! rotations
             C%CHART%d_out(1)=-C%CHART%d_out(1)
             C%CHART%d_out(2)=-C%CHART%d_out(2)
             C%CHART%ang_out(3)=-C%CHART%ang_out(3)
          ELSE
             C%CHART%d_in(1)=-C%CHART%d_in(1)
             C%CHART%d_in(2)=-C%CHART%d_in(2)
             C%CHART%ang_in(3)=-C%CHART%ang_in(3)
             CALL TRANS(C%CHART%d_in,X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                       !translation
             CALL ROT_XY(C%CHART%ang_in(3),X,OU)
             CALL ROT_XZ(C%CHART%ang_in(2),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)
             CALL ROT_YZ(C%CHART%ang_in(1),X,C%MAGP%P%BETA0,OU,C%MAGP%P%TIME)                ! rotations
             C%CHART%d_in(1)=-C%CHART%d_in(1)
             C%CHART%d_in(2)=-C%CHART%d_in(2)
             C%CHART%ang_in(3)=-C%CHART%ang_in(3)
          ENDIF
       ENDIF
    ENDIF
  END SUBROUTINE MIS_FIBP


  SUBROUTINE MIS_FIBS(C,Y,OU,ENTERING) ! Misaligns envelope fibres in PTC order for forward and backward fibres
    implicit none
    TYPE(FIBRE),INTENT(INOUT):: C
    type(ENV_8), INTENT(INOUT):: Y(6)
    type(REAL_8) X(6)
    logical(lp),INTENT(IN):: OU,ENTERING
    CALL ALLOC(X,6)
    X=Y
    CALL MIS_FIB(C,X,OU,ENTERING)
    Y=X
    CALL KILL(X,6)
  END SUBROUTINE MIS_FIBS

END MODULE S_TRACKING
