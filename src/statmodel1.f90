subroutine statmodel1(obsxy1,obsxy2,nperyear,lseries,series &
    ,mseries,lseries2,series2,mseries2,lpersist,nonc,mstart &
    ,fcstxy,nfcstens,yrstart,yrstop)

!       compute the cross--validated statistical forecast for a time
!       series

!       input:
!       obsxy1,obsxy2:observations pre-summed over the predictand and
!                     predictor seasons
!       series:       if ( lseries ) an extra predictor time series
!       mseries:                     starting at mseries
!       series2:      if ( lseries2) yet another predictor time series
!       mseries2:                    starting at mseries2
!       lpersist:     use persistence as a predictor?
!       nonc:         number of years to use for ONC, 0=no ONC
!       mstart:       starting month of the season of persistence
!       nfcstens:     number of ense,ble members to generate

!       output:
!       fcstxy:       nfcstens ensemble members of the forecasts

    implicit none
    include 'getopts.inc'
    integer,intent(in) :: nonc,mstart,mseries,mseries2,nfcstens
    integer,intent(inout) :: yrstart,yrstop
    real,intent(in) :: obsxy1(nperyear,yr1a:yr2a,0:nens2), &
        obsxy2(nperyear,yr1a:yr2a,0:nens2), &
        series(nperyear,yr1a:yr2a,0:nens2), &
        series2(nperyear,yr1a:yr2a,0:nens2)
    real,intent(out) :: fcstxy(nperyear,yr1:yr2,nfcstens)
    logical,intent(in) :: lseries,lseries2,lpersist

    integer :: yr,mo,yrf,i,ii,j,k,n,nperyear,month,iens
    real :: s,sig(1),a(2),da(2,2),chi2,q
    real,allocatable,save :: obs1(:,:),obs2(:,:),onc(:),sries(:,:) &
        ,sries2(:,:),indx(:),data(:),fcst(:),res(:)
    logical,save :: lfirst=.true.

    if ( lwrite ) then
        print *,'statmodel1: input'
        print *,'nperyear,yr1a,yr2a,nens1,nens2 = ', &
            nperyear,yr1a,yr2a,nens1,nens2
        print *,'yr1,yr2,nfcstens = ',yr1,yr2,nfcstens
        print *,'lseries,lseries2,lpersist,nonc = ',lseries,lseries2 &
            ,lpersist,nonc
    endif
    if ( lfirst ) then
        lfirst = .false. 
        if ( lwrite ) print *,'allocating arrays'
        allocate(obs1(yr1a:yr2a,nens1:nens2))
        allocate(obs2(yr1a:yr2a,nens1:nens2))
        if ( lseries ) allocate(sries(yr1a:yr2a,nens1:nens2))
        if ( lseries2) allocate(sries2(yr1a:yr2a,nens1:nens2))
        allocate(onc(yr1a:yr2a))
        allocate(indx((yr2a-yr1a+1)*(nens2-nens1+1)))
        allocate(data((yr2a-yr1a+1)*(nens2-nens1+1)))
        allocate(fcst(nfcstens))
        allocate(res(nfcstens))
        if ( lwrite ) print *,'done allocating'
    endif

    do month=m1,m2
    
!       cross-validate - make a new model for each year, leaving out that year
    
        do yrf=yr1,yr2
        
!           first check whether we can make a forecast at all
        
            fcstxy(month,yrf,:) = 3e33
            if ( mstart <= month ) then
                if  (yrf < yr1a .or. yrf > yr2a) then
                    if ( lwrite ) print *,'yrf not in range', &
                        yrf,yr1a,yr2a,'(',mstart,'<=',month,')'
                    cycle
                endif
                if ( lpersist .and. &
                     minval(obsxy2(mstart,yrf,:)) > 1e33 ) then
                    if ( lwrite ) print *,'no persistence obs',mstart,yrf
                    cycle
                endif
                if ( lseries ) then
                    if ( minval(series(mseries,yrf,:)) > 1e33 ) then
                        if ( lwrite ) print *,'no series obs',mseries,yrf
                        cycle
                    endif
                endif
                if ( lseries2 ) then
                    if ( minval(series2(mseries2,yrf,:)) > 1e33 ) &
                    then
                        if ( lwrite ) print *,'no series2 obs', &
                        mseries2,yrf
                        cycle
                    endif
                endif
            else            ! mstart > month
                if ( yrf <= yr1a .or. yrf > yr2a ) then
                    if ( lwrite ) print *,'yrf not in range', &
                        yrf,yr1a,yr2a,'(',mstart,'>',month,')'
                    cycle
                endif
                if ( lpersist .and. &
                minval(obsxy2(mstart,yrf-1,:)) > 1e33 ) then
                    if ( lwrite ) print *,'no persistence obs',mstart,yrf-1
                    cycle
                endif
                if ( lseries ) then
                    if ( minval(series(mseries,yrf-1,:)) > 1e33 ) then
                        if ( lwrite ) print *,'no series obs',mseries,yrf-1
                        cycle
                    endif
                endif
                if ( lseries2 ) then
                    if ( minval(series2(mseries2,yrf-1,:)) > 1e33 ) then
                        if ( lwrite ) print *,'no series2 obs',mstart,yrf-1
                        cycle
                    endif
                endif
            endif
            if ( lwrite ) print * &
                ,'mstart,mseries,mseries2,month,yrf = ' &
                ,mstart,mseries,mseries2,month,yrf
            do iens=nens1,nens2
                do yr=yr1a,yr2a
                    if ( yr /= yrf ) then
                        obs1(yr,iens) = obsxy1(month,yr,iens)
                    else
                        obs1(yr,iens) = 3e33
                    endif
                enddo
            enddo
            call checkseries('obs1',obs1,yr1,yr2,nens1,nens2)
            do iens=nens1,nens2
                do yr=yr1a,yr2a
                    obs2(yr,iens) = obsxy2(mstart,yr,iens)
                enddo
            enddo
            call checkseries('obs2',obs2,yr1,yr2,nens1,nens2)
            if ( lseries ) then
                do iens=nens1,nens2
                    do yr=yr1a,yr2a
                        sries(yr,iens) = series(mseries,yr,iens)
                    enddo
                enddo
                call checkseries('sries',sries,yr1,yr2,nens1,nens2)
            endif
            if ( lseries2 ) then
                do iens=nens1,nens2
                    do yr=yr1a,yr2a
                        sries2(yr,iens) = series2(mseries2,yr,iens)
                    enddo
                enddo
                call checkseries('sries2',sries2,yr1a,yr2a,nens1,nens2)
            endif

!           1) nonc-yr running mean climatology
!           this uses information from the past years in the
!           predictand season.  If there is not enough
!           information we use the years after the forecast year
!           (we assume the trend is mainly at the end, not the
!           beginning).  Note that when making a statistical model
!           of ensemble data we assume the ONC to be externally
!           forced, i.e., the same for all ensemble members.
        
            if ( nonc == 0 ) then
            
!               old-fashioned constant climatology
            
                call subclim(obs1,yr1a,yr2a,nens1,nens2,s,lwrite)
                if ( lwrite ) print *,'subtracting climatology',s
                if ( s < 1e33 ) then
                    fcst(:) = s
                else
                    fcst(:) = 3e33
                    cycle
                endif
                call subclim(obs2,yr1a,yr2a,nens1,nens2,s,lwrite)
                if ( lseries ) then
                    call subclim(sries,yr1a,yr2a,nens1,nens2,s,lwrite)
                endif
                if ( lseries2 ) then
                    call subclim(sries2,yr1a,yr2a,nens1,nens2,s,lwrite)
                endif
            else
                if ( lwrite ) print *,'subtracting onc ',nonc
            
!               climatology + Optimal Normal Correction:
!               climatology = mean last nonc years
            
                call subonc(obs1,yr1a,yr2a,nens1,nens2,nonc,onc,lwrite)
                if ( yrf >= yr1a .and. yrf <= yr2a ) then
                    fcst(:) = onc(yrf)
                endif
                call subonc(obs2,yr1a,yr2a,nens1,nens2,nonc,onc, .false. )
                if ( lseries ) then
                    call subonc(sries,yr1a,yr2a,nens1,nens2,nonc,onc, .false. )
                endif
                if ( lseries2 ) then
                    call subonc(sries2,yr1a,yr2a,nens1,nens2,nonc,onc, .false. )
                endif
            endif
            if ( lwrite ) print *,'clim fcst = ',fcst
        
!           2) persistence from mstart to month
        
            if ( lpersist ) then
                if ( lwrite ) print *,'subtracting persistence'
                call subfit(obs1,obs2,yr1a,yr2a,nens1,nens2,mstart &
                    ,month,yrf,fcst,nfcstens,data,indx,lwrite)
            endif
        
!           regression on series
        
            if ( lseries ) then
                if ( lwrite ) print *,'subtracting regression on series'
                call subfit(obs1,sries,yr1a,yr2a,nens1,nens2 &
                    ,mseries,month,yrf,fcst,nfcstens,data,indx &
                    ,lwrite)
            endif
        
!           regression on series2
        
            if ( lseries2 ) then
                if ( lwrite ) print *,'subtracting regression on series2'
                call subfit(obs1,sries2,yr1a,yr2a,nens1,nens2 &
                    ,mseries2,month,yrf,fcst,nfcstens,data,indx &
                    ,lwrite)
            endif
        
!           generate ensemble.
!           obs1 now contains the residuals of the model on all
!           other years
        
            if ( minval(fcst) < 1e33 ) then
                n = 0
                do iens=nens1,nens2
                    do yr=yr1a,yr2a
                        if ( obs1(yr,iens) < 1e33 ) then
                            n = n + 1
                            data(n) = obs1(yr,iens)
                        endif
                    enddo
                enddo
                if ( n > 0 ) then
                    call nrsort(n,data)
                    if ( lwrite ) print *,'generating ensemble from',n,data(1:n)
                    do iens=1,nfcstens
                        call getcut1(res(iens),100*iens/real(nfcstens+1),n,data,lwrite)
                    enddo
                    do iens=1,nfcstens
                        if ( fcst(iens) < 1e33 ) then
                            yrstart = min(yrstart,yrf)
                            yrstop  = max(yrstop,yrf)
                            fcstxy(month,yrf,iens) = fcst(iens) + res(iens)
                        else
                            fcstxy(month,yrf,iens) = 3e33
                        endif
                    enddo
                    if ( lwrite ) then
                        print *,'fcst,res,fcstxy(',month,yrf,':) = '
                        do i=1,nfcstens
                            print *,i,fcst(i),res(i),fcstxy(month,yrf,i)
                        enddo
                    endif
                endif
            endif
        enddo               ! yrf
    enddo                   ! month

end subroutine statmodel1

subroutine subclim(obs,yr1,yr2,nens1,nens2,s,lwrite)
    integer,intent(in) :: yr1,yr2,nens1,nens2
    real,intent(inout) :: obs(yr1:yr2,nens1:nens2),s
    logical :: lwrite
    integer :: n,iens,yr
    n = 0
    s = 0
    do iens=nens1,nens2
        do yr=yr1,yr2
            if ( obs(yr,iens) < 1e33 ) then
                n = n + 1
                s = s + obs(yr,iens)
            endif
        enddo
    enddo
    if ( n > 5 ) then
        s = s/n
        where ( obs < 1e33 ) obs = obs - s
    else
        s = 3e33
        obs = 3e33
    endif
end subroutine subclim

subroutine subonc(obs,yr1,yr2,nens1,nens2,nonc,onc,lwrite)
    implicit none
    integer,intent(in) :: yr1,yr2,nens1,nens2,nonc
    real,intent(inout) :: obs(yr1:yr2,nens1:nens2),onc(yr1:yr2)
    logical :: lwrite
    integer :: yrc,yr,iens,n,nens
    real :: s

    nens = nens2 - nens1 + 1
    do yrc = yr1,yr2
        n = 0
        s = 0
        if ( .false. .and. lwrite ) print *,'searching backwards'
        do yr=yrc-1,yr1,-1
            do iens=nens1,nens2
                if ( obs(yr,iens) < 1e33 ) then
                    n = n + 1
                    s = s + obs(yr,iens)
                    if ( n == nonc*nens ) exit
                endif
            enddo
        enddo
        if ( n < nonc ) then
            if ( .false. .and. lwrite ) print *,'searching forwards'
            do yr=yrc+1,yr2
                do iens=nens1,nens2
                    if ( obs(yr,iens) < 1e33 ) then
                        n = n + 1
                        s = s + obs(yr,iens)
                        if ( n == nonc*nens ) exit
                    endif
                enddo
            enddo
        endif
        if ( n < nonc*nens/2 ) then
!           not enough observations to make a model
            if ( lwrite ) print *,'not enough data'
            onc(yrc) = 3e33
            cycle
        endif
        if ( lwrite ) print *,'onc(',yrc,') = ',s/n
        onc(yrc) = s/n
        if ( onc(yrc) > 1e12 ) then
            write(*,*) 'subonc: error: onc(',yrc,') = ',onc(yrc)
        endif
    enddo
    do yr=yr1,yr2
        if ( obs(yr,nens1) < 1e33 .and. onc(yr) < 1e33 ) then
            obs(yr,:) = obs(yr,:) - onc(yr)
        else
            obs(yr,:) = 3e33
        endif
    enddo
end subroutine subonc

subroutine subfit(y,x,yr1,yr2,nens1,nens2,mstart,month,yrf,fcst &
    ,nfcstens,data,indx,lwrite)
    implicit none
    integer,intent(in) :: yr1,yr2,nens1,nens2,mstart,month,yrf,nfcstens
    real,intent(in) :: x(yr1:yr2,nens1:nens2)
    real,intent(inout) :: y(yr1:yr2,nens1:nens2)
    real,intent(out) :: fcst(1:nfcstens)
    real :: data((yr2-yr1+1)*(nens2-nens1+1)),indx((yr2-yr1+1)*(nens2-nens1+1))
    logical :: lwrite
    integer :: i,n,iens,yr,y1
    real :: a(2),da(2,2),sig(1),chi2,q

!   fill linear array with data

    n = 0
    do iens=nens1,nens2
        do yr=yr1,yr2
            if ( mstart <= month ) then
                y1 = yr
            else
                y1 = yr - 1
            endif
            if ( y1 < yr1 ) cycle
            if ( y(yr,iens) < 1e33 .and. x(y1,iens) < 1e33 ) then
                if ( abs(x(y1,iens)) > 1e18 .or. abs(y(yr,iens)) > 1e18 ) then
                    write(*,*)'statmodel1: error: x(',yr,iens,'),y(' &
                        ,y1,iens,') = ',x(y1,iens),y(yr,iens)
                else
                    n = n + 1
                    data(n) = y(yr,iens)
                    indx(n) = x(y1,iens)
                endif
            endif
        enddo               ! yr
    enddo                   ! iens
    if ( n >= 5 ) then
    
!       fit
    
        if ( .false. .and. lwrite ) then
            print *,'fitting'
            do i=1,n
                print *,i,indx(i),data(i)
            enddo
        endif
        call fit(indx,data,n,sig,0,a(2),a(1),da(2,2),da(1,1),chi2,q)
        if ( lwrite ) print *,'fit = ',a(1)
    
!       and apply the model to make a forecast
    
        if ( mstart <= month ) then
            y1 = yrf
        else
            y1 = yrf - 1
        endif
        if ( nens1 == nens2 ) then
            if ( x(y1,nens1) < 1e33 ) then
                where ( fcst < 1e33 ) fcst(:) = fcst(:) + a(1)*x(y1,nens1)
                if ( lwrite ) print *,'obs,fcst = ',x(y1,nens1),fcst(:)
            else
                fcst = 3e33
            endif
        elseif ( mod(nens2-nens1+1,nfcstens) == 0 ) then
            do iens=1,nfcstens
                i = nens1+mod(iens,nens2-nens1+1)
                if ( x(y1,i) < 1e33 .and. fcst(iens) < 1e33 ) then
                    fcst(iens) = fcst(iens) + a(1)*x(y1,i)
                else
                    fcst(iens) = 3e33
                endif
            enddo
        else
            write(0,*) 'statmodel1: cannot yet handle ', &
                'the case nens1,nens2,nfcstens = ' &
                ,nens1,nens2,nfcstens
            call exit(-1)
        endif
    
!       finally subtract the model from the predictands
    
        do yr=yr1,yr2
            if ( mstart <= month ) then
                y1 = yr
            else
                y1 = yr - 1
            endif
            if ( y1 < yr1 ) cycle
            if ( nens1 == nens2 ) then
                if ( y(yr,nens1) < 1e33 .and. &
                x(y1,nens1) < 1e33 ) then
                    y(yr,nens1) = y(yr,nens1) - a(1)*x(y1,nens1)
                else
                    y(yr,nens1) = 3e33
                endif
            elseif ( mod(nens2-nens1+1,nfcstens) == 0 ) then
                do iens=nens1,nens2
                    if ( y(yr,iens) < 1e33 .and. &
                    x(y1,iens) < 1e33 ) then
                        y(yr,iens) = y(yr,iens) - a(1)*x(y1,iens)
                    else
                        y(yr,iens) = 3e33
                    endif
                enddo
            else
                write(0,*) 'statmodel1: cannot yet handle ', &
                    'the case nens1,nens2,nfcstens = ' &
                    ,nens1,nens2,nfcstens
                call exit(-1)
            endif
            if ( lwrite ) then
                do iens=nens1,nens2
                    if ( y(yr,iens) < 1e33 .and. abs(y(yr,iens)) > 1e18 ) then
                        print *,'error in subfit ',yr,iens,y(yr,iens),a(1),x(y1,iens)
                    endif
                enddo
            endif
        enddo
    else
        fcst(:) = 3e33
    endif
end subroutine subfit

subroutine checkseries(string,obs,yr1,yr2,nens1,nens2)
    implicit none
    integer,intent(in) :: yr1,yr2,nens1,nens2
    real,intent(in) :: obs(yr1:yr2,nens1:nens2)
    character,intent(in) :: string*(*)
    integer :: yr,iens

    do iens=nens1,nens2
        do yr=yr1,yr2
            if ( obs(yr,iens) < 1e33 .and. obs(yr,iens) > 1e12 ) then
                write(*,*) 'checkseries: error: ',string,'(',yr1,iens,') = ',obs(yr,iens)
            endif
        enddo
    enddo
end subroutine checkseries
