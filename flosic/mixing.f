C UTEP Electronic Structure Lab (2019)
C
C
C++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      SUBROUTINE MIXING(MODE,NITER,ALPHA,JTOP,NAMES)
C WRITTEN BY DUANE D JOHNSON (1988)
C MODIFIED FOR HAMLTONIAN MIXING BY LUIS BASURTO (2014)
       use mixpot1,only :POTIN,POTOUT,HAMMIXIN,HAMMIXOUT,
     &                   DMATMIXIN,DMATMIXOUT
!       use common3,only : RMAT
!       use common5,only : HOLD
!       use common8,only : REP
! Conversion to implicit none.  Raja Zope Thu Aug 17 14:34:53 MDT 2017

!      INCLUDE  'PARAMAS'  
       INCLUDE  'PARAMA2'  
       INTEGER :: NITER, JTOP, IMATSZ, I, IERR, IP, ITER, IVSIZ, J, K,
     & LASTIT, LASTM1, LASTM2, LM, LN, LTMP, MAXITER, MAXSIZ, MODE
       REAL*8 :: SYMBOL , ALPHA, A, AIJ, AMIX, B, CM, CMJ, D, DFNORM,
     & FAC1, FAC2, FNORM, GMI, ONE, W, W0, WTMP, ZERO
       SAVE
C      REAL*8 B,D
C MODE 1 IS FOR POTENTIAL MIXING
C
C MODE 2 IS FOR HAMILTONIAN MIXING
C
C MODE 3 IS FOR DENSITY MATRIX MIXING
C
C************************************************************
C*  THE VECTORS UI(MAXSIZ) AND VTI(MAXSIZ) ARE JOHNSON'S    *
C*  U(OF I ) AND DF(TRANSPOSE), RESPECTIVELY. THESE ARE     *
C*  CONTINUALLY UPDATED. ALL ITERATIONS ARE STORED ON TAPE  *
C*  32 . THIS IS DONE TO PREVENT THE PROHIBITIVE STORAGE    *
C*  COSTS ASSOCIATED WITH HOLDING ONTO THE ENTIRE JACOBIAN. *
C*  VECTOR TL IS THE VT OF EARLIER ITERATIONS. VECTOR F IS: *
C*  VECTOR(OUTPUT) - VECTOR(IN). VECTOR DF IS:  F(M+1)-F(M) *
C*  FINALLY,VECTOR DUMVI(MAXSIZ) IS THE PREDICTED VECTOR.   *
C************************************************************
C*  FOR THE CRAY2-CIVIC ENVIRONMENT , FILES 32 AND 31       *
C*  SHOULD BE INTRODUCED IN THE LINK STATEMENT.             *
C++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      PARAMETER (MAXSIZ=MAX_PTS*MXSPN)
      PARAMETER (ZERO=0.0D0,ONE=1.0D0,IMATSZ=40)
C
C ADDED PARAMETER MAXITER. POREZAG, MAY 1995
C
      PARAMETER(MAXITER=15)
C
C++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
C
      CHARACTER*7 NAMES
C
C SCRATCH COMMON BLOCK FOR LOCAL VARIABLES
C
C      COMMON/TMP1/F(MAXSIZ),UI(MAXSIZ),VTI(MAXSIZ),T1(MAXSIZ),
C     &       VECTOR(MAXSIZ,2),DUMVI(MAXSIZ),DF(MAXSIZ)
C      COMMON/MIXPOT/POTIN(MAX_PTS*MXSPN),POTOUT(MAX_PTS*MXSPN)
      DIMENSION NAMES(3)
      DIMENSION A(IMATSZ,IMATSZ),B(IMATSZ,IMATSZ),CM(IMATSZ)
      DIMENSION D(IMATSZ,IMATSZ),W(IMATSZ)
      REAL*8,ALLOCATABLE :: F(:),UI(:),VTI(:),T1(:),VECTOR(:,:),
     &                      DUMVI(:),DF(:)
C
C NEW LINES POREZAG, MAY 1995
C
      ITER=NITER
      IF(NITER.GT.MAXITER)ITER=MOD(ITER,MAXITER)+1
      IF(ITER.EQ.0)RETURN
C
C END NEW LINES
C

C
C ALLOCATE LOCAL ARRAYS
C
      ALLOCATE(F(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING F'
      ALLOCATE(UI(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING UI'
      ALLOCATE(VTI(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING VTI'
      ALLOCATE(T1(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING T1'
      ALLOCATE(VECTOR(MAXSIZ,2),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING VECTOR'
      ALLOCATE(DUMVI(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING DUMVI'
      ALLOCATE(DF(MAXSIZ),STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR ALLOCATING DF'

      OPEN(66,FILE=NAMES(1),STATUS='UNKNOWN',FORM='FORMATTED')
      CLOSE (66,STATUS='DELETE')
      OPEN(66,FILE=NAMES(1),STATUS='UNKNOWN',FORM='FORMATTED')
      REWIND(66)
      IF(ITER.EQ.1)THEN
       OPEN(31,FILE=NAMES(2),STATUS='UNKNOWN',FORM='UNFORMATTED')
       OPEN(32,FILE=NAMES(3),STATUS='UNKNOWN',FORM='UNFORMATTED')
       CLOSE(31,STATUS='DELETE')
       CLOSE(32,STATUS='DELETE')
      END IF
C
      OPEN(31,FILE=NAMES(2),STATUS='UNKNOWN',FORM='UNFORMATTED')
      OPEN(32,FILE=NAMES(3),STATUS='UNKNOWN',FORM='UNFORMATTED')
      REWIND(31)
      REWIND(32)
C
C++++++ SET UP THE VECTOR OF THE CURRENT ITERATION FOR MIXING ++++++
C
C  FOR THIS METHOD WE HAVE ONLY SAVED INPUT/OUTPUT CHG. DENSITIES,
      SELECT CASE(MODE)
      CASE(1)
          DO K=1,JTOP
            VECTOR(K,1)= POTIN(K)
            VECTOR(K,2)= POTOUT(K)
          END DO
      CASE(2)
          DO K=1,JTOP
            VECTOR(K,1)= HAMMIXIN(K)
            VECTOR(K,2)= HAMMIXOUT(K)
          END DO
      CASE(3)
          DO K=1,JTOP
            VECTOR(K,1)= DMATMIXIN(K)
            VECTOR(K,2)= DMATMIXOUT(K)
          END DO
      END SELECT
!      IF(MODE.EQ.1) THEN
!       DO K=1,JTOP
!        VECTOR(K,1)= POTIN(K)
!        VECTOR(K,2)= POTOUT(K)
!       END DO
!      ELSE
!       DO K=1,JTOP
!        VECTOR(K,1)= HAMMIXIN(K)
!        VECTOR(K,2)= HAMMIXOUT(K)
!       END DO
!      ENDIF
C++++++ END OF PROGRAM SPECIFIC LOADING OF VECTOR FROM MAIN ++++++++
C
C  IVSIZ IS THE LENGTH OF THE VECTOR
      IVSIZ=JTOP
C     IF(ITER.LT.3)WRITE( 6,1001)IVSIZ
      IF(IVSIZ.GT.MAXSIZ)THEN
       PRINT *,'MIXING: EXCEEDED MAXIMAL VECTOR LENGTH'
       CALL STOPIT
      END IF
C
C
C*******************  BEGIN BROYDEN'S METHOD  **********************
C
C  WEIGHTING FACTOR FOR THE ZEROTH ITERATION
      W0=0.01D0
C
C      F:  THE DIFFERENCE OF PREVIOUS OUTPUT AND INPUT VECTORS
C  DUMVI:  A DUMMY VECTOR, HERE IT IS THE PREVIOUS INPUT VECTOR
      REWIND(31)
      READ(31,END=119,ERR=119)AMIX,LASTIT
C> Vout - Vin
      READ(31)(F(K),K=1,IVSIZ)
C> Vin from last iter
      READ(31)(DUMVI(K),K=1,IVSIZ)
C> coef matrix
      READ(31)LTMP,((A(I,J),I=1,LTMP),J=1,LTMP)
C> Weighting factor
      READ(31)(W(I),I=1,LTMP)
C
C  ALPHA(OR AMIX)IS SIMPLE MIXING PARAMETERS
      WRITE(66,1002)AMIX,ITER+1
C
      DO K=1,IVSIZ
C> Vin - Vin from last iter
        DUMVI(K)=VECTOR(K,1)-DUMVI(K)
C> F(K) - F(k) from last iter
        DF(K)=VECTOR(K,2)-VECTOR(K,1)-F(K)
      END DO
      DO K=1,IVSIZ
C> Vout - Vin
        F(K)=VECTOR(K,2)-VECTOR(K,1)
      END DO
C
C  FOR I-TH ITER.,DFNORM IS ( F(I) MINUS F(I-1) ), USED FOR NORMALIZATION
C
      DFNORM=ZERO
      FNORM=ZERO
      DO K=1,IVSIZ
        DFNORM=DFNORM + DF(K)*DF(K)
        FNORM=FNORM + F(K)*F(K)
      END DO
      DFNORM=SQRT(DFNORM)
      FNORM=SQRT(FNORM)
      WRITE(66,'(''  DFNORM '',E13.6,'' FNORM '',E13.6)')DFNORM,FNORM
C
      FAC2=ONE/DFNORM
      FAC1=AMIX*FAC2
C
      DO K=1,IVSIZ
C> (DF(K) + a*dVin)/DFNORM
        UI(K) = FAC1*DF(K) + FAC2*DUMVI(K)
C> DF(K)/DFNORM
        VTI(K)= FAC2*DF(K)
      ENDDO
C
C*********** CALCULATION OF COEFFICIENT MATRICES *************
C***********    AND THE SUM FOR CORRECTIONS      *************
C
C RECALL: A(I,J) IS A SYMMETRIC MATRIX
C       : B(I,J) IS THE INVERSE OF [ W0**2 I + A ]
C
         LASTIT=LASTIT+1   ! current iter
         LASTM1=LASTIT-1   ! last iter
         LASTM2=LASTIT-2   ! last last iter
C         write(6,*)'LTMP',LTMP,'LASTM1',LASTM1
C
C DUMVI IS THE U(OF I) AND T1 IS THE VT(OF I)
C FROM THE PREVIOUS ITERATIONS
      REWIND(32)
      WRITE(66,1003)LASTIT,LASTM1 ! current iter, last iter
      IF(LASTIT.GT.2)THEN         ! 3rd iter in mixing (4th actual iter I think)
      DO 500 J=1,LASTM2
      READ(32)(DUMVI(K),K=1,IVSIZ)
      READ(32)(T1(K),K=1,IVSIZ)
C
      AIJ=ZERO
      CMJ=ZERO
      DO K=1,IVSIZ
        CMJ=CMJ + T1(K)*F(K)
        AIJ=AIJ + T1(K)*VTI(K)
      END DO
      A(LASTM1,J)=AIJ
      A(J,LASTM1)=AIJ
            CM(J)=CMJ
  500 CONTINUE
      ENDIF
C
      AIJ=ZERO
      CMJ=ZERO
      DO K=1,IVSIZ
        CMJ= CMJ + VTI(K)*F(K)
        AIJ= AIJ + VTI(K)*VTI(K)
      END DO
      A(LASTM1,LASTM1)=AIJ
            CM(LASTM1)=CMJ
C
      WRITE(32)(UI(K),K=1,IVSIZ)
      WRITE(32)(VTI(K),K=1,IVSIZ)
      REWIND(32)
C
C THE WEIGHTING FACTORS FOR EACH ITERATION HAVE BEEN CHOSEN
C EQUAL TO ONE OVER THE R.M.S. ERROR. THIS NEED NOT BE THE CASE.
       IF(FNORM .GT. 1.0D-7)THEN
         WTMP=0.010D0/FNORM
       ELSE
         WTMP=1.0D5
       END IF
       IF(WTMP.LT. 1.00D0)WTMP=1.00D0
       W(LASTM1)=WTMP
       WRITE(66,'(''  WEIGHTING SET =  '',E13.6)')WTMP
C
C
C WITH THE CURRENT ITERATIONS F AND VECTOR CALCULATED,
C WRITE THEM TO UNIT 31 FOR USE LATER.
      REWIND(31)
      WRITE(31)AMIX,LASTIT
      WRITE(31)(F(K),K=1,IVSIZ)
      WRITE(31)(VECTOR(K,1),K=1,IVSIZ)
      WRITE(31)LASTM1,((A(I,J),I=1,LASTM1),J=1,LASTM1)
      WRITE(31)(W(I),I=1,LASTM1)
C
C SET UP AND CALCULATE BETA MATRIX
      DO LM=1,LASTM1
        DO LN=1,LASTM1
          D(LN,LM)= A(LN,LM)*W(LN)*W(LM)
          B(LN,LM)= ZERO
        END DO
        B(LM,LM)= ONE
        D(LM,LM)= W0**2 + A(LM,LM)*W(LM)*W(LM)
      END DO
C
      CALL INVERSE(D,B,LASTM1)
C
C  CALCULATE THE VECTOR FOR THE NEW ITERATION
      DO K=1,IVSIZ
        DUMVI(K)= VECTOR(K,1) + AMIX*F(K) !This is smiple mixing
      END DO
C
      DO 504 I=1,LASTM1
      READ(32)(UI(K),K=1,IVSIZ)
      READ(32)(VTI(K),K=1,IVSIZ)
      GMI=ZERO
      DO 503 IP=1,LASTM1
  503 GMI=GMI + CM(IP)*B(IP,I)*W(IP)
      DO 504 K=1,IVSIZ
  504 DUMVI(K)=DUMVI(K)-GMI*UI(K)*W(I)
C  END OF THE CALCULATION OF DUMVI, THE NEW VECTOR
C
      REWIND(31)
      REWIND(32)
C
      GOTO 120
C IF THIS IS THE FIRST ITERATION, THEN LOAD
C    F=VECTOR(OUT)-VECTOR(IN) AND VECTOR(IN)
  119 CONTINUE
      REWIND(31)
      LASTIT=1
      AMIX=ALPHA
      DO K=1,IVSIZ
        F(K)=VECTOR(K,2)-VECTOR(K,1)
      END DO
      WRITE(31)AMIX,LASTIT
      WRITE(31)(F(K),K=1,IVSIZ)
      WRITE(31)(VECTOR(K,1),K=1,IVSIZ)
      WRITE(31)LASTM1,((A(I,J),I=1,LASTM1),J=1,LASTM1)
      WRITE(31)(W(I),I=1,LASTM1)
C
C SINCE WE ARE ON THE FIRST ITERATION, SIMPLE MIX THE VECTOR.
      DO K=1,IVSIZ
        DUMVI(K)= VECTOR(K,1) + AMIX*F(K)
      END DO
C     WRITE( 6,1000)
  120 CONTINUE
C
      CLOSE(31,STATUS='KEEP')
      CLOSE(32,STATUS='KEEP')
C
C*************  THE END OF THE BROYDEN METHOD **************
C
C+++++++ PROGRAM SPECIFIC CODE OF RELOADING ARRAYS +++++++++
C
C NEED TO UNLOAD THE NEW VECTOR INTO THE APPROPRIATE ARRAYS.
       SELECT CASE(MODE)
       CASE(1)
             DO K=1,JTOP
               POTIN(K)=DUMVI(K)
             END DO
       CASE(2)
             DO K=1,JTOP
               HAMMIXIN(K)=DUMVI(K)
             END DO
       CASE(3)
             DO K=1,JTOP
               DMATMIXIN(K)=DUMVI(K)
             END DO
       END SELECT
!      IF(MODE.EQ.1)THEN
!        DO K=1,JTOP
!          POTIN(K)=DUMVI(K)
!        END DO
!      ELSE
!        DO K=1,JTOP
!          HAMMIXIN(K)=DUMVI(K)
!        END DO
!      ENDIF
C
C+++++++++ END OF PROGRAM SPECIFIC RELOADING OF ARRAYS +++++++++
C
      WRITE(66,1004)ITER+1
      CLOSE(66)
C
C DEALLOCATE LOCAL ARRAYS
C     
      DEALLOCATE(F,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING F'
      DEALLOCATE(UI,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING UI'
      DEALLOCATE(VTI,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING VTI'
      DEALLOCATE(T1,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING T1'
      DEALLOCATE(VECTOR,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING VECTOR'
      DEALLOCATE(DUMVI,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING DUMVI'
      DEALLOCATE(DF,STAT=IERR)
      IF(IERR.NE.0) WRITE(6,*)'MIXING:ERROR DEALLOCATING DF'

      RETURN
C
C1000 FORMAT(' ---->  STRAIGHT MIXING ON THIS ITERATION')
C1001 FORMAT(' IN MIXING:   IVSIZ =',I7,/)
 1002 FORMAT(' IN MIXING: SIMPLE MIX PARAMETER',1(F10.6,',')
     >      ,'  FOR ITER=',I5)
 1003 FORMAT(' CURRENT ITER= ',I5,' INCLUDES VALUES FROM ITER=',I5)
 1004 FORMAT(10X,'DENSITY FOR ITERATION',I4,' PREPARED')
      END
