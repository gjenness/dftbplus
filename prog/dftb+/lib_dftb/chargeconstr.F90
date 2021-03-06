!--------------------------------------------------------------------------------------------------!
!  DFTB+: general package for performing fast atomistic simulations                                !
!  Copyright (C) 2017  DFTB+ developers group                                                      !
!                                                                                                  !
!  See the LICENSE file for terms of usage and distribution.                                       !
!--------------------------------------------------------------------------------------------------!

!!* Contains routines for the additional local potential, which should enforce
!!* charge constraints.
module chargeconstr
#include "assert.h"
#include "allocate.h"
  use accuracy
  implicit none
  private

  public :: OChrgConstr, init, destruct
  public :: buildShift, addShiftPerAtom, addEnergyPerAtom

  type OChrgConstr
    private
    logical :: tInit
    integer :: nAtom
    integer :: kappa
    real(dp), pointer :: refCharges(:) => null()
    real(dp), pointer :: prefactors(:) => null()
    real(dp), pointer :: shift(:) => null()
  end type OChrgConstr

  interface init
    module procedure ChrgConstr_init
  end interface

  interface destruct
    module procedure ChrgConstr_destruct
  end interface

  interface buildShift
    module procedure ChrgConstr_buildShift
  end interface
  
  interface addShiftPerAtom
    module procedure ChrgConstr_addShiftPerAtom
  end interface

  interface addEnergyPerAtom
    module procedure ChrgConstr_addEnergyPerAtom
  end interface


contains

  !* Initializes
  !* @param sf
  !* @param inp Array contining reference charges and prefactors (nAtom, 2)
  !* @param kappa exponent of the local potential to add
  subroutine ChrgConstr_init(sf, inp, kappa)
    type(OChrgConstr), intent(inout) :: sf
    real(dp), intent(in) :: inp(:,:)
    integer, intent(in) :: kappa
    
    ASSERT(.not. sf%tInit)
    ASSERT(size(inp, dim=1) > 0)
    ASSERT(size(inp, dim=2) == 2)

    sf%nAtom = size(inp, dim=1)
    ALLOCATE_PARR(sf%refCharges, (sf%nAtom))
    ALLOCATE_PARR(sf%prefactors, (sf%nAtom))
    ALLOCATE_PARR(sf%shift, (sf%nAtom))
    sf%refCharges = inp(:,1)
    sf%prefactors = inp(:,2)
    sf%kappa = kappa
    sf%tInit = .true.
    
  end subroutine ChrgConstr_init


  
  subroutine ChrgConstr_destruct(sf)
    type(OChrgConstr), intent(inout) :: sf

    ASSERT(sf%tInit)
    
    DEALLOCATE_PARR(sf%refCharges)
    DEALLOCATE_PARR(sf%prefactors)
    DEALLOCATE_PARR(sf%shift)
    sf%tInit = .false.

  end subroutine ChrgConstr_destruct


  
  subroutine ChrgConstr_buildShift(sf, chargesPerAtom)
    type(OChrgConstr), intent(inout) :: sf
    real(dp), intent(in) :: chargesPerAtom(:)

    ASSERT(sf%tInit)
    ASSERT(size(chargesPerAtom) == size(sf%shift))

    sf%shift = real(sf%kappa, dp) * sf%prefactors &
        &* (chargesPerAtom - sf%refCharges)**(sf%kappa - 1)
    
  end subroutine ChrgConstr_buildShift

  

  subroutine ChrgConstr_addShiftPerAtom(sf, shiftPerAtom)
    type(OChrgConstr), intent(inout) :: sf
    real(dp), intent(inout) :: shiftPerAtom(:)

    ASSERT(sf%tInit)
    ASSERT(size(shiftPerAtom) == sf%nAtom)

    shiftPerAtom = shiftPerAtom + sf%shift

  end subroutine ChrgConstr_addShiftPerAtom


  
  subroutine ChrgConstr_addEnergyPerAtom(sf, energyPerAtom, chargesPerAtom)
    type(OChrgConstr), intent(inout) :: sf
    real(dp), intent(inout) :: energyPerAtom(:)
    real(dp), intent(in) :: chargesPerAtom(:)

    ASSERT(sf%tInit)
    ASSERT(size(energyPerAtom) == sf%nAtom)
    ASSERT(size(energyPerAtom) == sf%nAtom)

    energyPerAtom = energyPerAtom &
        &+ sf%shift * (chargesPerAtom - sf%refCharges) / real(sf%kappa, dp)

  end subroutine ChrgConstr_addEnergyPerAtom


end module chargeconstr
