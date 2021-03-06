module quadratures
  !-----------------------------------------------------------------------------
  ! Module: quadratures
  !  This modules contains subroutines for computing and testing numerical
  !  quadratures.
  !
  ! Subroutines:
  !  gausslegendre (public)
  !   Compute the Gauss-Legendre quadrature of degree N using the Golub-Welsh
  !   algorithm.
  !
  !  gausslegendre_shifted (public)
  !   Compute the Gauss-Legendre quadrature of degree N using the Golub-Welsh
  !   algorithm and map to the interval (0, 1).
  !
  !  gausslegendre_truncated (public)
  !   Compute the Gauss-Legendre quadrature of degree 2N using the Golub-Welsh
  !   algorithm and truncate returning only the positive gridpoints.
  !
  !  polytest (public)
  !   Test an integral quadrature against the analytic solution of an integral
  !   of the form integral[a,b] x^{m} dx
  !
  ! Useful Citations:
  !  Golub, Gene H., and John H. Welsch. "Calculation of Gauss
  !  quadrature rules." Mathematics of computation (1969): 221-230.
  !---
  ! Developed by J.P. Dark
  ! Contact: email@jpdark.com
  ! Last modified June 2017
  !-----------------------------------------------------------------------------


  implicit none

  integer, parameter :: sp = kind(1.0)
  integer, parameter :: dp = kind(1.d0)
  real(dp), parameter :: PI = 3.141592653589793_dp


  private
  public :: gausslegendre, gausslegendre_truncated, gausslegendre_shifted, &
       clencurt, polytest

contains

  subroutine gausslegendre(N, mu, wt)
    !!------------------------------------------------------------------------
    !! Name: gausslegendre
    !!  Compute the Gauss-Legendre quadrature of degree N using the
    !!  Golub-Welsh algorithm.
    !!
    !! Synopsis
    !!  subroutine gausslegendre(N, mu, wt)
    !!
    !!    INPUT
    !!     Integer ------------- N
    !!
    !!    OUTPUT
    !!     Double precision ---- mu(N), wt(N)
    !!
    !! Purpose
    !!  Compute the Nth order Gauss-Legendre with quadrature points mu and
    !!  the associated weigths wt on the interval (-1, 1).
    !!
    !!  Citation:
    !!  Golub, Gene H., and John H. Welsch. "Calculation of Gauss
    !!  quadrature rules." Mathematics of computation (1969): 221-230.
    !!
    !!
    !! Arguments N (input) integer The number of quadrature points.
    !!
    !!  mu (output) double precision, array(N)
    !!    Quadrature points.
    !!
    !!  wt (output) double precision, array(N)
    !!    Associated weights.
    !!------------------------------------------------------------------------
    implicit none
    integer(8), intent(in) :: N
    real(dp), intent(out), dimension(N) :: mu, wt
    real(dp) :: z(N, N)
    real(dp) :: e(N-1)
    real(dp) :: work(N-1, N-1)
    real(dp) :: tmp
    integer(8) :: info
    integer(8) :: mm
    if (mod(N, 2) /= 0) then
       write(*, *) &
            '> WARNING: Quadrature contains the origin.'
    endif
    mu = 0.0_dp
    do mm = 1, N-1
       tmp = 1.0_dp / (2.0_dp * real(mm, dp)) ** 2
       e(mm) = 0.5_dp / dsqrt(1.0_dp - tmp)
    enddo
    call dsteqr('I', N, mu, e, z, N, work, info)
    do mm = 1, N
       wt(mm) = 2.0_dp * z(1, mm) ** 2
    enddo
  end subroutine gausslegendre


  subroutine gausslegendre_shifted(N, mu, wt)
    !!------------------------------------------------------------------------
    !! Name: gausslegendre_shifted
    !!  Compute the Gauss-Legendre quadrature of degree N using the
    !!  Golub-Welsh algorithm and map to the interval (0, 1)
    !!
    !! Synopsis
    !!  subroutine gausslegendre(N, mu, wt)
    !!
    !!    INPUT
    !!     Integer ------------- N
    !!
    !!    OUTPUT
    !!     Double precision ---- mu(N), wt(N)
    !!
    !! Purpose
    !!  Compute the Nth order Gauss-Legendre with quadrature points mu and
    !!  the associated weigths wt on the interval (-1, 1) and shift using
    !!  linear transform
    !!
    !!     mu   -->  0.5 * (mu + 1)
    !!
    !!  into the interval (0, 1).
    !!
    !!  Citation:
    !!   Golub, Gene H., and John H. Welsch. "Calculation of Gauss
    !!   quadrature rules." Mathematics of computation (1969): 221-230.
    !!
    !!
    !! Arguments
    !!     N (input) integer
    !!       The number of quadrature points.
    !!
    !!     mu (output) double precision, array(N)
    !!       Quadrature points.
    !!
    !!     wt (output) double precision, array(N)
    !!       Associated weights.
    !!------------------------------------------------------------------------
    implicit none
    integer(8), intent(in) :: N
    real(dp), intent(out) :: mu(N), wt(N)
    real(dp) :: z(N, N)
    real(dp) :: e(N-1)
    real(dp) :: work(N-1, N-1)
    real(dp) :: tmp
    integer(8) :: info
    integer(8) :: mm
    mu = 0.0_dp
    do mm = 1, N-1
       tmp = 1.0_dp / (2.0_dp * real(mm, dp)) ** 2
       e(mm) = 0.5_dp / dsqrt(1.0_dp - tmp)
    enddo
    call dsteqr('I', N, mu, e, z, N, work, info)
    mu = 0.5_dp * (mu + 1.0_dp)
    do mm = 1, N
       wt(mm) = z(1, mm) ** 2
    enddo
  end subroutine gausslegendre_shifted


  subroutine gausslegendre_truncated(N, mu, wt)
    !!--------------------------------------------------------------------------
    !! Name: gausslegendre_truncated
    !!  Compute the Gauss-Legendre quadrature of degree 2N using the
    !!  Golub-Welsh algorithm and truncate returning the positive gridpoints.
    !!
    !! Synopsis
    !!  subroutine gausslegendre(N, mu, wt)
    !!
    !!    INPUT
    !!     Integer ------------- N
    !!
    !!    OUTPUT
    !!     Double precision ---- mu(N), wt(N)
    !!
    !! Purpose
    !!  Compute the (2*N)th order Gauss-Legendre with quadrature points mu and
    !!  the associated weigths wt on the interval (-1, 1) and return the N
    !!  gridpoints and associated weights on the interval (0, 1).
    !!
    !!     Citation:
    !!     Golub, Gene H., and John H. Welsch. "Calculation of Gauss
    !!     quadrature rules." Mathematics of computation (1969): 221-230.
    !!
    !!
    !! Arguments
    !!  N (input) integer
    !!    The number of quadrature points.
    !!
    !!  mu (output) double precision, array(N)
    !!    Quadrature points.
    !!
    !!  wt (output) double precision, array(N)
    !!    Associated weights.
    !!---------------------------------------------------------------------------
    implicit none
    integer(8), intent(in) :: N
    real(dp), dimension(N) :: mu, wt
    real(dp), dimension(2*N) :: x
    real(dp) :: z(2*N, 2*N)
    real(dp) :: e(2*N-1)
    real(dp) :: work(2*N-1, 2*N-1)
    real(dp) :: tmp
    integer(8) :: info
    integer(8) :: mm
    x = 0.0_dp
    do mm = 1, 2*N-1
       tmp = 1.0_dp / (2.0_dp * real(mm, dp)) ** 2
       e(mm) = 0.5_dp / dsqrt(1.0_dp - tmp)
    enddo
    call dsteqr('I', 2*N, x, e, z, 2*N, work, info)
    mu = x(N+1:2*N)
    do mm = 1, N
       wt(mm) = 2.0_dp * z(1, N + mm) ** 2
    enddo
  end subroutine gausslegendre_truncated


  subroutine clencurt(N, mu, wt)
    !!--------------------------------------------------------------------------
    !! Name: gausslegendre_truncated
    !!  Compute the Clenshaw-Curtis quadrature of degree N for even N.
    !!
    !! Synopsis
    !!  subroutine clencurt(N, mu, wt)
    !!
    !!    INPUT
    !!     Integer ------------- N
    !!
    !!    OUTPUT
    !!     Double precision ---- mu(N), wt(N)
    !!
    !! Purpose
    !!  Compute the Clenshaw-Curtis quadrature on the interval [-1, 1].
    !!
    !!   *Method adapted from Matlab function in book:
    !!       Spectral Methods in MATLAB by Lloyd N. Trefethen (p.128).
    !!
    !! Arguments
    !!  N (input) integer
    !!    The number of quadrature points (even).
    !!
    !!  mu (output) double precision, array(N)
    !!    Quadrature points.
    !!
    !!  wt (output) double precision, array(N)
    !!    Associated weights.
    !!---------------------------------------------------------------------------
    implicit none
    integer(8), intent(in) :: N
    real(dp), intent(out), dimension(N) :: mu, wt
    real(dp), dimension(N) :: theta
    integer(8) :: M
    real(dp) :: tmp1
    integer(8) :: ii, jj

    !---------------------------------------------------------------------------
    ! Chebyshev gridpoints mu = cos(theta) where theta[n] = pi * (n-1) / N.
    !
    theta(1) = 0.0_dp
    tmp1 = PI / real(N-1, dp)
    do ii = 1, N-1
       theta(ii+1) = tmp1 * real(ii, dp)
    enddo
    mu = cos(theta)
    !---------------------------------------------------------------------------

    !---------------------------------------------------------------------------
    ! Compute weight
    !
    M = N-1
    if (mod(N, 2) .eq. 0) then
       wt(1) = 1.0_dp / real((N-1) ** 2, dp)
       wt(N) = wt(1)
       wt(2:M) = 1.0_dp
       do jj = 1, N/2-1
          ! wt -= 2 * cos(2 * j * theta) / (4 * j^2 - 1)
          tmp1 = real(2 * jj ** 2, dp) - 0.5_dp
          wt(2:M) = wt(2:M) - cos(2.0_dp * real(jj, dp) * theta(2:M)) &
               / tmp1
       enddo
       ! wt *= 2 / (M)
       wt(2:M) = wt(2:M) / (real(N/2, dp) - 0.5_dp)
    else
       write(*, '(A)') '> Warning in __quadratures_MOD_clencurt'
       write(*, '(A)') &
            '> Warning: Odd number of quadrature points - origin is included.'

       wt(1) = 1.0_dp / real(M ** 2 - 1, dp)
       wt(N) = wt(1)
       wt(2:M) = 1.0_dp
       do jj = 1, M/2 - 1
          ! wt -= 2 * cos(2 * j * theta) / (4 * j^2 - 1)
          tmp1 = real(2 * jj ** 2, dp) - 0.5_dp
          wt(2:M) = wt(2:M) - cos(2.0_dp * real(jj, dp) * theta(2:M)) &
               / tmp1
       enddo
       ! wt -= cos((M) * theta) / ((M)^2 - 1)
       wt(2:M) = wt(2:M) - cos(real(M, dp) * theta(2:M)) &
            / real(M ** 2 - 1, dp)
       ! wt *= 2 / (M)
       wt(2:M) = wt(2:M) / real(M/2, dp)
    endif


  end subroutine clencurt




  subroutine polytest(N, m, a, b, x, wt)
    !!--------------------------------------------------------------------------
    !! Name: polytest
    !!  Test an integral quadrature against the analytic solution of an integral
    !!  of the form integral[a,b] x^{m} dx
    !!
    !!
    !! Synopsis
    !!     subroutine polytest( N, M, a, b, x, wt )
    !!
    !!     Integer ------------- N, M
    !!     Double precision ---- a, b, x( N ), wt( N )
    !!
    !! Purpose
    !!  Compute the integral
    !!
    !!     I = Integral_{a}^{b} x^{M} dx
    !!
    !!  both analytically,
    !!
    !!     I_true = 1/(M+1) (b^{M+1} - a^{M+1}),
    !!
    !!  and with the quadrature,
    !!
    !!     I_quad = sum[n=1,N] x(n)^m * wt(n).
    !!
    !!  Compare the results to verify the correctness of the quadrature.
    !!
    !! Arguments
    !!  N (input) integer
    !!    The number of quadrature points.
    !!
    !!  M (input) integer
    !!    Order of the polynomial in integral.
    !!
    !!  a (output) double precision, array(N)
    !!    Start point of the interval the quadrature is defined on.
    !!
    !!  b (output) double precision, array(N)
    !!    End point of the interval the quadrature is defined on.
    !!
    !!  x (output) double precision, array(N)
    !!    Quadrature points.
    !!
    !!  wt (output) double precision, array(N)
    !!    Associated weights.
    !!---------------------------------------------------------------------------
    implicit none
    ! Input
    integer(8), intent(in) :: N
    integer, intent(in) :: M
    real(dp), intent(in) :: a, b
    real(dp), intent(in), dimension(N) :: x, wt
    ! Workspace
    real(dp) :: approximate, analytic
    if (M .eq. -1) then
       analytic = log(b) - log(a)
    else
       analytic = (b ** (M+1) - a ** (M+1)) / real(M+1, dp)
    endif
    approximate = sum(x ** M * wt)
    write(*, '(A, F4.1, A, F4.1, A, I4)') &
         '> Integrate x^m from b to a where: a = ', a, ', b = ',  b, &
         ', m =  ', M
    write(*, '(A, F8.6,A, F8.6, A, E12.4)') 'Analytic = ', analytic, &
    '; Numeric =  ', approximate, '; Error = ', analytic - approximate
    write(*,*) ""
  end subroutine polytest

end module quadratures
