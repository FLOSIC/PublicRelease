C UTEP Electronic Structure Lab (2019)
C
C> @file mldecomp.f
C> NEWWAVES
C> Path diverges depending on ATOMSIC and FRMORB files
       SUBROUTINE NEWWAVES(ITTOT,TRACE)
       IMPLICIT REAL*8 (A-H,O-Z)
       CHARACTER*50 LINE
       LOGICAL EXIST
       INQUIRE(FILE='ATOMSIC', EXIST = EXIST)
       IF(.NOT.EXIST)THEN
         INQUIRE(FILE='FRMORB',EXIST=EXIST)
         IF(EXIST) THEN
           CALL SCFSICW(ITTOT,TRACE)
C          call system('echo LDA >XXTEST')
C          call system('grep GGA SYMBOL > XXTEST')
C          OPEN(38,FILE='XXTEST')
C          READ(38,'(A50)')LINE
C          DO I=1,47
C            IF(LINE(I:I+2).EQ.'GGA')STOP'GGA IS NOT READY'
C          END DO
C          CLOSE(38)
         ELSE
           CALL NEWWAVE_serial(ITTOT,TRACE)
         END IF
       ELSE
         INQUIRE(FILE='PURGRSQ',EXIST=EXIST)
         OPEN(54,FILE='PURGRSQ')
         IF(EXIST)READ(54,*,END=10)EXIST
 10      CONTINUE
         IF(.NOT.EXIST)THEN
           REWIND(54)
           WRITE(54,*)'.TRUE.'
           PRINT*,'RERUN WITH NEW PURGRSQ'
           CALL STOPIT
         END IF
         CLOSE(54)
         OPEN(54,FILE='XMOL.DAT')
         READ(54,*)NATM
         CLOSE(54)
         OPEN(54,FILE='GRPMAT')
         READ(54,*)MXXG
         CLOSE(54)
         IF(NATM.NE.1.OR.MXXG.NE.1)THEN
           PRINT*,' ATOMS:',NATM
           PRINT*,'GRPMAT:',MXXG
           PRINT*,'SICWAVE SHOULD NOT BE CALLED'
           CALL STOPIT
         END IF
         !CALL SICWAVE(ITTOT,TRACE)
         print *,"SICWAVE is not merged yet in this versio  YY"
         call stopit !YY 
       END IF
       RETURN
       END
