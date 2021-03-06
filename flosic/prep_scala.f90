! UTEP Electronic Structure Lab (2019)

SUBROUTINE PREP_SCALA(N)
USE HSTOR1
IMPLICIT NONE
INTEGER,INTENT(IN) :: N
REAL*8,ALLOCATABLE :: A(:,:)
INTEGER            :: I,J,K

ALLOCATE(A(N,N),STAT=I)
IF(I/=0) WRITE(6,*)'PREP_SCALA: ERROR ALLOCATING A'
K=1
DO I=1,N
  DO J=I,N
    A(J,I)=HSTOR(K,2)
    A(I,J)=A(J,I)
    K=K+1
  ENDDO
ENDDO
OPEN(16,FILE='HAMTOT',FORM='UNFORMATTED')
WRITE(16)((A(I,J),J=1,N),I=1,N)
CLOSE(16)
K=1
DO I=1,N
  DO J=I,N
    A(J,I)=HSTOR(K,1)
    A(I,J)=A(J,I)
    K=K+1
  ENDDO
ENDDO
OPEN(16,FILE='OVLTOT',FORM='UNFORMATTED')
WRITE(16)((A(I,J),J=1,N),I=1,N)
CLOSE(16)
DEALLOCATE(A,STAT=I)
IF(I/=0) WRITE(6,*)'PREP_SCALA: ERROR DEALLOCATING A'
RETURN
END SUBROUTINE PREP_SCALA
