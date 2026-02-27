# previous test case had eta5 as main eta for h6
# also previously wrong eta_i values in AC kernels
# This test is for the 3-phase KKS model
###########################################################################################################################
# The multicomponent is represented by the suffixes a and b for ternary system A-B-C
# For multiphase system with eta1, eta2, and eta3, the suffixes 1,2 and 3 come after the variables and materials properties  
############################################################################################################################
[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 35 #30 #30 #25 #16 #20 #15 #20 #100 #30 #20 #25 #20 #40 #50 #20
  ny = 35 #30 #30 #25 #16 #20 #15 #20 #100 #30 #20 #25 #20 #40 #50 #20
  nz = 0
  xmin = 0
  xmax = 500 #80
  ymin = 0
  ymax = 500 #50
  zmin = 0
  zmax = 0
  elem_type = QUAD4
[]
#########################################################################################


#########################################################################################
[BCs]
  [./Periodic]
    [./all]
      #auto_direction = 'x y'
      auto_direction = 'x'
    [../]
  [../]
  
  [./neumann1]
        type = NeumannBC
        boundary = 'bottom'
        variable = 'eta3'
        value = 0
    [../]
    [./neumann2]
       type = NeumannBC
        boundary = 'top'
        variable = 'eta1'
        value = 0
   [../]
[]
#########################################################################################


#########################################################################################
[AuxVariables]
  [./bnds]
  [../]
  [./Energy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./gr_c]
   order = CONSTANT
   family = MONOMIAL
  [../]
[]
#########################################################################################


#########################################################################################

[Variables]
# For A-B-C alloy, cA+cB+cC = 1
# So, DOF = 2 i.e. cA and cB are sufficient to describe the composition of the ternary system A-B-C
############################################
  # potential variable used in SplitCHCRes and kkssplitchcres (global)
  [./wa] #A 
    order = FIRST
    family = LAGRANGE
    #scaling = 1.0E+02
  [../]
  
#  [./wb] # B
#    order = FIRST
#    family = LAGRANGE
#    ###scaling = 1.0E-02
#  [../]
############################################
 
############################################
  # concentration (global) of A
  [./ca]
    order = FIRST
    family = LAGRANGE
    #scaling = 1.0E+04
  [../]
  
   # concentration (global) of B
 # [./cb]
 #   order = FIRST
 #   family = LAGRANGE
 #   ###scaling = 1.0E+02
 # [../]
############################################

################################################################ 
# Phase concentrations corresponding to global composition cA
############################################################### 
  # phase concentration 1
  [./c1a]
    order = FIRST
    family = LAGRANGE
    #initial_condition = 0.2
    #scaling = 1.0E+04
  [../]
######################

######################
  # phase concentration 2
  [./c2a]
    order = FIRST
    family = LAGRANGE
    #initial_condition = 0.5
    #scaling = 1.0E+04
  [../]
######################

######################
  # phase concentration 3
  [./c3a]
    order = FIRST
    family = LAGRANGE
    #initial_condition = 0.8
    #scaling = 1.0E+04
  [../]
############################################
################################################################ 
# Phase concentrations corresponding to global composition cB
############################################################### 
  # phase concentration 1
 # [./c1b]
 #   order = FIRST
 #   family = LAGRANGE
 #   #initial_condition = 0.2
 #   ###scaling = 1.0E+02
 # [../]
######################

######################
  # phase concentration 2
#  [./c2b]
#    order = FIRST
#    family = LAGRANGE
#    #initial_condition = 0.5
#    ###scaling = 1.0E+02
#  [../]
######################

######################
  # phase concentration 3
 # [./c3b]
 #   order = FIRST
 #   family = LAGRANGE
 #   #initial_condition = 0.8
 #   ###scaling = 1.0E+02
 # [../]
############################################


############################################
  # order parameter 1 FCC
  [./eta1]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################

######################
  # order parameter 2 IMC
  [./eta2]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################

######################
  # order parameter 3 LIQUID
  [./eta3]
    order = FIRST
    family = LAGRANGE
    #initial_condition = 0.0
    scaling = 1.0E-04
  [../]
  
  ######################
  # order parameter 2
  [./eta4]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################
######################
  # order parameter 2
  [./eta5]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################
 ######################
  # order parameter 2
  [./eta6]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################
######################
  # order parameter 2
  [./eta7]
    order = FIRST
    family = LAGRANGE
    scaling = 1.0E-04
  [../]
######################
######################
#  # order parameter 2
#  [./eta8]
#    order = FIRST
#    family = LAGRANGE
#    scaling = 1.0E-04
#  [../]
######################
[]
#########################################################################################
###########Upto here#####################################


#########################################################################################

[ICs]

############################################
    [./eta1]  # extends from y = 0 to y = 20 , x no change
        variable = eta1
        type = FunctionIC
        function = 'if(y<=250,1,0)'
    [../]
######################

######################    
    [./eta2] # extends from y = 20 to y = 30 , x no change
        variable = eta2
        type = FunctionIC
        #function = 'if(y>20&y<=30,1,0)'
        #function = 'if(y>200&y<=250&x>15&x<=75,1,0)'
        function = 'r:=sqrt((x-60)^2+(y-250)^2);if(y<=250,0,if(r<=45,1,0))'
        #function = 'if(y>=250&y<=340&x>15&x<=105,1,0)'
    [../]
######################
 [./eta3] # extends from y = 20 to y = 30 , x no change
        variable = eta3
        type = FunctionIC
        #function = 'if(y>30,1,0)'
        #function = 'if(y<=200,0,if(y>250&y<=250&x>15&x<=75,0,if(y>200&y<=250&x>105&x<=195,0,if(y>200&y<=250&x>225&x<=315,0,if(y>200&y<=250&x>345&x<=385,0,if(y>200&y<=250&x>415&x<=485,0,1))))))'
       function = 'r2:=sqrt((x-60)^2+(y-250)^2); r4:=sqrt((x-165)^2+(y-250)^2); r5:=sqrt((x-270)^2+(y-250)^2); r6:=sqrt((x-370)^2+(y-250)^2); r7:=sqrt((x-460)^2+(y-250)^2); r8:=sqrt((x-555)^2+(y-250)^2);if(y<=250,0,if(r2<=45,0,if(r4<=30,0,if(r5<=45,0,if(r6<=25,0,if(r7<=35,0,1))))))'
         #function = 'if(y<250,0,if(y>=250&y<=340&x>15&x<=105,0,if(y>=250&y<=310&x>135&x<=195,0,if(y>=250&y<=340&x>225&x<=315,0,if(y>=250&y<=300&x>345&x<=395,0,if(y>=250&y<=320&x>425&x<=495,0,if(y>=250&y<=310&x>525&x<=585,0,1)))))))'
[../]
######################
    [./eta4] # extends from y = 20 to y = 30 , x no change
        variable = eta4
        type = FunctionIC
        #function = 'if(y>30,1,0)'
        #function = 'if(y>200&y<=250&x>105&x<=195,1,0)'
        function = 'r:=sqrt((x-165)^2+(y-250)^2);if(y<=250,0,if(r<=30,1,0))'
        #function = 'if(y>=250&y<=310&x>135&x<=195,1,0)'
    [../]
############################################
[./eta5] # extends from y = 20 to y = 30 , x no change
        variable = eta5
        type = FunctionIC
        #function = 'if(y>30,1,0)'
        #function = 'if(y>200&y<=250&x>225&x<=315,1,0)'
        function = 'r:=sqrt((x-270)^2+(y-250)^2);if(y<=250,0,if(r<=45,1,0))'
        #function = 'if(y>=250&y<=340&x>225&x<=315,1,0)'
[../]

#################################################
[./eta6] # extends from y = 20 to y = 30 , x no change
        variable = eta6
        type = FunctionIC
        #function = 'if(y>30,1,0)'
        #function = 'if(y>200&y<=250&x>345&x<=385,1,0)'
        function = 'r:=sqrt((x-370)^2+(y-250)^2);if(y<=250,0,if(r<=25,1,0))'
        #function = 'if(y>=250&y<=300&x>345&x<=395,1,0)'
        
[../]

#################################################
[./eta7] # extends from y = 20 to y = 30 , x no change
        variable = eta7
        type = FunctionIC
        #function = 'if(y>30,1,0)'
        #function = 'if(y>200&y<=250&x>415&x<=485,1,0)'
        function = 'r:=sqrt((x-460)^2+(y-250)^2);if(y<=250,0,if(r<=35,1,0))'
        #function = 'if(y>=250&y<=320&x>425&x<=495,1,0)'
[../]

#################################################
#[./eta8] # extends from y = 20 to y = 30 , x no change
#        variable = eta8
#        type = FunctionIC
#        #function = 'if(y>30,1,0)'
#        #function = 'if(y>200&y<=250&x>415&x<=485,1,0)'
#        #function = 'r:=sqrt((x-555)^2+(y-250)^2);if(y<=250,0,if(r<=30,1,0))'
#        function = 'if(y>250&y<=310&x>525&x<=585,1,0)'
#[../]

############################################
    [./ca] #Global Composition of A for ternary A-B-C alloy
        variable = ca
        type = FunctionIC
        #function = 'if(y<=20,0.01,0)+if(y>20&y<=30,0.667,0)+if(y>30,0.95,0)'
        function = 'r2:=sqrt((x-60)^2+(y-250)^2); r4:=sqrt((x-165)^2+(y-250)^2); r5:=sqrt((x-270)^2+(y-250)^2); r6:=sqrt((x-370)^2+(y-250)^2); r7:=sqrt((x-460)^2+(y-250)^2); r8:=sqrt((x-555)^2+(y-250)^2); 0.01*if(y<=250,1,0)+0.455*if(y<=250,0,if(r2<=45,1,if(r4<=30,1,if(r5<=45,1,if(r6<=25,1,if(r7<=35,1,1))))))+0.95*if(y<=250,0,if(r2<=45,0,if(r4<=30,0,if(r5<=45,0,if(r6<=25,0,if(r7<=35,0,1))))))'  
        #function = '0.01*if(y<=250,1,0)+0.455*if(y>250&y<=340&x>15&x<=105,1,if(y>250&y<=310&x>135&x<=195,1,if(y>250&y<=340&x>225&x<=315,1,if(y>250&y<=300&x>345&x<=395,1,if(y>250&y<=320&x>425&x<=495,1,if(y>250&y<=310&x>525&x<=585,1,0))))))+0.95*if(y<250,0,if(y>250&y<=340&x>15&x<=105,0,if(y>250&y<=310&x>135&x<=195,0,if(y>250&y<=340&x>225&x<=315,0,if(y>250&y<=300&x>345&x<=395,0,if(y>250&y<=320&x>425&x<=495,0,if(y>250&y<=310&x>525&x<=585,0,1)))))))'    
 [../]
############################################  
 #[./cb] #Global Composition of B for ternary A-B-C alloy
 #       variable = cb
 #       type = FunctionIC
 #       #function = 'if(y<=20,0.01,0)+if(y>20&y<=30,0.667,0)+if(y>30,0.95,0)'
 #       function = '0.94*if(y<=20,1,0)+0.267*if(y>20&y<=30&x>5&x<=15,1,if(y>20&y<=35&x>20&x<=30,1,if(y>20&y<=30&x>35&x<=45,1,0)))+0.02*if(y<=20,0,if(y>20&y<=30&x>5&x<=15,0,if(y>20&y<=35&x>20&x<=30,0,if(y>20&y<=30&x>35&x<=45,0,1))))'      
# [../]

[]

########################################################################################
#####upto here####################################################################### 08.05.2023 Monday

########################################################################################

[Materials]
##When kappa is increased by a factor of f_kappa=energy_scale/length_scale, simulation converges at factor_f1 = 1.0E+07
# When f_kappa=1, factor_f1 = 1.0E+09
############################################
  # simple toy free energies
  [./f1] # this phase is expected to shrink
    type = DerivativeParsedMaterial
    f_name = F1
    args = 'c1a'
    material_property_names = 'length_scale energy_scale'
    constant_names = 'factor_f1'
    constant_expressions = '1.00E+06' #'1.0E+08' '1.0E+08'
    function = '(energy_scale/(length_scale)^3) *(1.112e+04*(c1a-0.01)^2 -2.19e+03*(c1a-0.01)-1.33e+03)*factor_f1'
    #constant_expressions = '1.00E+04' #'1.0E+08' '1.0E+08'
    #function = '(energy_scale/(length_scale)^3) *(70.6*(c1a-0.2)^2 + 7.2*(c1a-0.2)-9.7)*factor_f1'
    #function = '1.0E+05*(-0.01+0.02*(c1a-0.2)^2)'
  [../]
######################

######################
  [./f2] # this phase is expected to grow
    type = DerivativeParsedMaterial
    f_name = F2
    args = 'c2a'
    material_property_names = 'length_scale energy_scale'
    constant_names = 'factor_f2'
    constant_expressions = '1.00E+06' #'1.0E+08' '1.0E+08'
    function = '(energy_scale/(length_scale)^3) *(2.347e+04*(c2a-0.36)^2+1.65e+03*(c2a-0.36)-1.92e+03-16.50e+03)*factor_f2' #The term -9.50e+03 accounts for compensation of dc/dr
    #function = '(energy_scale/(length_scale)^3) *(2.347e+04*(c2a-0.36)^2+1.65e+03*(c2a-0.36)-1.92e+03-9.50e+03)*factor_f2' #The term -9.50e+03 accounts for compensation of dc/dr
    #function = '(energy_scale/(length_scale)^3) *(2.347e+04*(c2a-0.447)^2+1.65e+03*(c2a-0.447)-1.92e+03-8.50e+03)*factor_f2' #The term -8.50e+03 accounts for compensation of dc/dr
    #function = '(energy_scale/(length_scale)^3) *(2.347e+04*(c2a-0.38)^2+1.65e+03*(c2a-0.38)-1.92e+03-8.50e+03)*factor_f2' #The term -8.50e+03 accounts for compensation of dc/dr
    #constant_expressions = '1.0E+04' #'1.0E+08' '1.0E+08'
    #function = '(energy_scale/(length_scale)^3) *(690.00*(c2a-0.667)^2+290.00*(c2a-0.667)-20.0)*factor_f2'
    #function = '(energy_scale/(length_scale)^3) *(95.4*(c2a-0.667)^2+34*(c2a-0.667)-20.0)*factor_f2'
  [../]
######################

######################
  [./f3] # this phase is expected to shrink
    type = DerivativeParsedMaterial
    f_name = F3
    args = 'c3a'
    material_property_names = 'length_scale energy_scale'
    constant_names = 'factor_f3'
    constant_expressions = '1.00E+06' #'1.0E+08' '1.0E+08'
    #function = '(energy_scale/(length_scale)^3) *(75.0*(c3a-0.95)^2+15*(c3a-0.95)-8.8)*factor_f3'
    function = '(energy_scale/(length_scale)^3) *(1.762e+04*(c3a-0.97)^2+0.41e+03*(c3a-0.97)-1.53e+03)*factor_f3'
    #constant_expressions = '1.00E+04' #'1.0E+08' '1.0E+08'
    #function = '(energy_scale/(length_scale)^3) *(75.0*(c3a-0.95)^2+15*(c3a-0.95)-8.8)*factor_f3'
  [../]
############################################
  
  
############################################
#SwitchingFunction        ## Eq 10,11 of https://doi.org/10.1016/j.actamat.2010.10.038 A quantitative and thermodynamically Moelans 2011
   [./h1]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h1
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta1
        #outputs = exodus
    [../]
######################
######################

######################
   [./h2]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h2
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta2
        #outputs = exodus
    [../]
######################

######################
    [./h3]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h3
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7 '
        phase_etas = eta3
        #outputs = exodus
    [../] 
############################################

######################
    [./h4]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h4
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta4
        #outputs = exodus
    [../] 
############################################

######################
    [./h5]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h5
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta5
        #outputs = exodus
    [../] 
############################################

######################
    [./h6]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h6
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta6
        #outputs = exodus
    [../] 
############################################
######################
    [./h7]
        type = SwitchingFunctionMultiPhaseMaterial
        h_name = h7
        all_etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
        phase_etas = eta7
        #outputs = exodus
    [../] 
############################################



############################################    
    # Barrier functions for each phase
  [./g1]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta1
    function_name = g1
  [../]
######################

######################
  [./g2]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta2
    function_name = g2
  [../]
######################

######################
  [./g3]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta3
    function_name = g3
  [../]
############################################

######################
  [./g4]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta4
    function_name = g4
  [../]
############################################

######################
  [./g5]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta5
    function_name = g5
  [../]
############################################

######################
  [./g6]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta6
    function_name = g6
  [../]
############################################

######################
  [./g7]
    type = BarrierFunctionMaterial
    g_order = SIMPLE
    eta = eta7 
    function_name = g7
  [../]
############################################

############################################
# constant properties M is needed by SplitCHWRes kernel

  [./constants_mobility] #maximum limit for convergence 1.0E-17 
    type = GenericConstantMaterial
    prop_names  = 'pseudo_L_si   pseudo_kappa  D  M_si_fcc M_si_imc M_si_liq  pseudo_mu'
    prop_values = '50   0.5   1  1.028e-23 1.028e-22 1.028e-21  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  5.028e-23 5.028e-22 5.028e-21  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-21 1.0e-20 1.0e-19  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-20 1.0e-19 1.0e-18  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-20 1.0e-19 1.0e-18  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-29 1.0e-28 1.0e-27  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-28 1.0e-27 1.0e-26  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-20 1.0e-19 1.0e-18  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '50   0.5   1  1.0e-19  500 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '10  0.5   1  8  1.5 500 ' #Perfect for factor_fi=1.0
    #prop_values = '1000 0.5   1  800 1.5 1000' #perfect
    #prop_values = '100.0 0.5   1  80.0 1.5 1000'
    #prop_values = '50.0 0.5   1  40.0 1.5 500' # converged
    #prop_values = '10.0 0.5   1  10.0 1.5 1000' #solve converged once
    #prop_values = '1.0 1.0    1  1.0 1.5 500' #more more better
    #prop_values = '1.0 1.0    1  1.0 1.5 150' #more more better
    #prop_values = '1.0 5.0    1  1.0 1.5 0.5' # more better
    #prop_values = '0.17 5.0    1  0.1 1.5 0.5' #better
    #prop_values = '0.0017 0.005    1  0.001 1.5 0.05' # no convergence
    #prop_values = '0.017 5.0    1  0.01 1.5 0.5' # good
  [../]
############################################
#####44.45 nm is the least thickness of delta for 6.67 criterion
#####making delta = 500 nm brought convergence at dt = 100 ns
[./constants_interface]
    type = GenericConstantMaterial
    prop_names  = 'gamma sigma delta length_scale energy_scale time_scale'
    prop_values = '1.5 0.5   35E-09  1e9 6.24150943e18 1.0e9 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '1.5 0.5   35E-09  1e9 6.24150943e18 1.0e9 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '1.5 0.5   55E-09  1e9 6.24150943e18 1.0e9 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '1.5 0.5   25E-09  1e9 6.24150943e18 1.0e9 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
    #prop_values = '1.5 0.5   40E-09  1e9 6.24150943e18 1.0e9 ' # L must be 10 or greater (Eureka for convergence test) Ratio between fbulk to L, M, m and kappa important
[../]
  ################################################33
[./kappa]
    type = ParsedMaterial
    material_property_names = 'sigma delta length_scale energy_scale'
    f_name = kappa
    constant_names = 'factor_kappa' # factor_kappa = factor_sigma*factor_delta = 2*10  (works at dt = 1000), 2*8=16.0 also works; 1.5*15 = 22.5 too works, 2*1000 = 2000 works
    constant_expressions = '10' #'200' #'200' #'20' #'20.0' #'18.0' #'22.50' # 1.0E-1 to make the kappa scaled from 702.225 to 70.225 so that its magnitude is less than scaled fbulk's absolute magnitude
    function = '(energy_scale/length_scale)*0.75*sigma*delta*factor_kappa' #eV/nm
  [../]
  [./mu]
    type = ParsedMaterial
    material_property_names = 'sigma delta length_scale energy_scale'
    f_name = mu
    constant_names = 'factor_mu' #factor_mu = factor_sigma/factor_delta = 2/10 = 0.2 (works at dt = 1000), 2/8 = 0.25 also works, 1.5/15=0.1 too works, 2/1000=0.002 works
    constant_expressions = '2.5' #'8.0' #'2.0' #'0.2' #'0.05' #'8.0' #'4.80E+00' #'1.0E-01'
    function = '(energy_scale/(length_scale)^3)*6*(sigma/delta)*factor_mu' #eV/nm^3
  [../]
############################################
 [./interface_mobility] # considered the same in isotropic and anisotropic
    type = ParsedMaterial
    #material_property_names = 'M_si mu kappa'
    f_name = L
    constant_names = 'factor_L'
    constant_expressions = '1.0E+00' # To make the scaled quantity in the range of 5
    material_property_names = 'length_scale energy_scale time_scale M mu kappa' # We will later use M_si instead of M because of unit reasons
    function = '((length_scale)^3/(energy_scale*time_scale))*(16/3)*(mu*M/kappa)*factor_L' #l^3/energy*time
  [../]


  [./ch_mobility] # considered the same in isotropic and anisotropic
    type = ParsedMaterial
    #material_property_names = 'M_si'
    f_name = M
    #args = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7 eta8'
    material_property_names = 'length_scale energy_scale time_scale M_si_fcc M_si_imc M_si_liq  M_gb h1 h2 h3 h4 h5 h6 h7 '
    function = '((length_scale)^5/(energy_scale*time_scale))*((h2+h4+h5+h6+h7)*M_si_imc+h1*M_si_fcc+h3*M_si_liq+(h2+h4+h5+h6+h7)*(h2+h4+h5+h6+h7)*M_gb)' #l^5/energy*time
  [../]
  
  [./M_gb]
    type = ParsedMaterial
    material_property_names = 'M_si_imc'
    f_name = M_gb
    function = '5*M_si_imc'
    #function = '25*M_si_imc'
    #function = '35*M_si_imc' # 4 non-convergence to reach 1st convergence
    #function = '50*M_si_imc' #  4 non-convergence to reach 1st convergence
    #function = '20*M_si_imc' # 3 non-convergence to reach 1st convergence, compared to Mgb=200Mimc, this model converges well and GB is resolves better earlier owing to slow growth 
    #function = '200*M_si_imc'
    #function = '400*M_si_imc'# compared to Mgb=200Mimc, this model convergence is difficult and GB is not resolved better  owing to faster growth 
  [../]

[]

########################################################################################



########################################################################################

[Kernels]

############################################
######## First put the KKS condition with kernels of phase concentrations (local) related to cA global #######

############################################
# Phase concentration constraints
  [./chempot12a]
    type = KKSPhaseChemicalPotential
    variable = c1a
    cb       = c2a
    fa_name  = F1
    fb_name  = F2
  [../]
######################

######################
  [./chempot23a]
    type = KKSPhaseChemicalPotential
    variable = c2a
    cb       = c3a
    fa_name  = F2
    fb_name  = F3
  [../]
############################################

############################################
  [./phaseconcentration_a]
    type = KKSMultiPhaseConcentration
    variable = c3a
    cj = 'c1a c2a c3a c2a c2a c2a c2a'
    hj_names = 'h1 h2 h3 h4 h5 h6 h7'
    etas = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
    c = ca
  [../]
############################################

############################################
######## First put the KKS condition for kernels of phase concentrations (local) related to cB global #######

############################################
# Phase concentration constraints
#  [./chempot12b]
#    type = KKSPhaseChemicalPotential
#    variable = c1b
#    cb       = c2b
#    fa_name  = F1
#    fb_name  = F2
#  [../]
######################

######################
#  [./chempot23b]
#    type = KKSPhaseChemicalPotential
#    variable = c2b
#    cb       = c3b
#    fa_name  = F2
#    fb_name  = F3
#  [../]
############################################

############################################
#  [./phaseconcentration_b]
#    type = KKSMultiPhaseConcentration
#    variable = c3b
#    cj = 'c1b c2b c3b c2b c2b'
#    hj_names = 'h1 h2 h3 h4 h5'
#    etas = 'eta1 eta2 eta3 eta4 eta5'
#    c = cb
#  [../]
############################################

############################################
## Kernels for split Cahn-Hilliard type equation
    ## CHBulk known as KKSSplitCHCRes is here to replace SplitCHParsed
    ## because in KKS model , gradient energy term is not allowed in the C-H type equation [Tonks2018-ComputationalMaterialsScience,vol. 147, pp.353-362.]
    ## while SplitCHParsed kernel consists of the term k\nabla^2 c_i (thus making it unsuitable here), KKSSplitCHCRes fortunately avoids this term.
    ## Never use SplitCHParsed kernel with KKS model
    ## Because of the KKS condition 1 (equality of chemical potential between any two adjacent phases), one KKSSplitCHCRes kernel (either for c1, c2 or c3) is sufficient and there is no need to put three such kernels corresponding to c1, c2 and c3.

##############################################################################3  
# Diffusion kernels corresponding to phase concentrations of global cA
########################################################################  
    [./CHBulka] # Gives the residual for the concentration, dF/dc-mu
        type = KKSSplitCHCRes
        variable = ca
        ca       = c2a
        fa_name  = F2 #only F2 is used
        w        = wa
    [../]
############################################

############################################
    [./dcdta] # Gives dc/dt
        type = CoupledTimeDerivative
        variable = wa
        v = ca
    [../]
############################################

############################################    
    [./ckernela] # Gives residual for chemical potential dc/dt+M\grad(mu)
        type = SplitCHWRes
        mob_name = M
        variable = wa
        args = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
    [../]
############################################

##############################################################################3  
# Diffusion kernels corresponding to phase concentrations of global cB
########################################################################  
#    [./CHBulkb] # Gives the residual for the concentration, dF/dc-mu
#        type = KKSSplitCHCRes
#        variable = cb
#        ca       = c2b
#        fa_name  = F2 #only F2 is used
#        w        = wb
#    [../]
############################################

############################################
#    [./dcdtb] # Gives dc/dt
#        type = CoupledTimeDerivative
#        variable = wb
#        v = cb
#    [../]
############################################

############################################    
#    [./ckernelb] # Gives residual for chemical potential dc/dt+M\grad(mu)
#        type = SplitCHWRes
#        mob_name = M
#        variable = wb
#        args = 'eta1 eta2 eta3 eta4 eta5 eta6'
#    [../]
############################################

##################################################################

  # Kernels for Allen-Cahn equation for eta1
  
######################  
  [./deta1dt]
    type = TimeDerivative
    variable = eta1
  [../]
######################  
######################################################################################################################################
###################################################################################################################
  [./ACBulkF1]
    type = KKSMultiACBulkF
    variable  = eta1
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g1
    eta_i     = eta1
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta2 eta3 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################
###############################################################################################################
# In ACBulkC1, the kernel requires  the definition of a particular element (A or B) as a separate list of vectors
################################################################################################################
######################  
  [./ACBulkC1a]
    type = KKSMultiACBulkC
    variable  = eta1
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta1
    args      = 'eta2 eta3 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################
 #[./ACBulkC1b]
 #   type = KKSMultiACBulkC
 #   variable  = eta1
 #   Fj_names  = 'F1 F2 F3 F2 F2'
 #   hj_names  = 'h1 h2 h3 h4 h5'
 #   cj_names  = 'c1b c2b c3b c2b c2b'
 #   eta_i     = eta1
 #   args      = 'eta2 eta3 eta4 eta5 '
 #   mob_name = L
 # [../]

######################################################################################################################################
######################  
  [./ACInterface1]
    type = ACInterface
    variable = eta1
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta1] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta1
      v = 'eta2 eta3 eta4 eta5 eta6 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta2 eta3 eta4 eta5 eta6 eta7'
[../]
 
##################################################################

  # Kernels for Allen-Cahn equation for eta2
  
######################
  [./deta2dt]
    type = TimeDerivative
    variable = eta2
  [../]
######################

######################  
  [./ACBulkF2]
    type = KKSMultiACBulkF
    variable  = eta2
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g2
    eta_i     = eta2
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta1 eta3 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################

######################
  [./ACBulkC2a]
    type = KKSMultiACBulkC
    variable  = eta2
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta2
    args      = 'eta1 eta3 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################
# [./ACBulkC2b]
#    type = KKSMultiACBulkC
#    variable  = eta2
#    Fj_names  = 'F1 F2 F3 F2 F2'
#    hj_names  = 'h1 h2 h3 h4 h5'
#    cj_names  = 'c1b c2b c3b c2b c2b'
#    eta_i     = eta2
#    args      = 'eta1 eta3 eta4 eta5'
#    mob_name = L
#  [../]

######################  
  [./ACInterface2]
    type = ACInterface
    variable = eta2
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
#################################################################
[./ACdfintdeta2] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta2
      v = 'eta1 eta3 eta4 eta5 eta6 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta3 eta4 eta5 eta6'
[../]
#################################################################
  # Kernels for Allen-Cahn equation for eta4
  
######################
  [./deta4dt]
    type = TimeDerivative
    variable = eta4
  [../]
######################

######################  
  [./ACBulkF4]
    type = KKSMultiACBulkF
    variable  = eta4
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g4
    eta_i     = eta4
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta1 eta3 eta2 eta5 eta6 eta7'
    mob_name = L
  [../]
######################

######################
  [./ACBulkC4a]
    type = KKSMultiACBulkC
    variable  = eta4
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta4
    args      = 'eta1 eta3 eta2 eta5 eta6 eta7'
    mob_name = L
  [../]
  
 #  [./ACBulkC4b]
 #   type = KKSMultiACBulkC
 #   variable  = eta2
 #   Fj_names  = 'F1 F2 F3 F2 F2'
 #   hj_names  = 'h1 h2 h3 h4 h5'
 #   cj_names  = 'c1b c2b c3b c2b c2b'
 #   eta_i     = eta4
 #   args      = 'eta1 eta3 eta2 eta5'
 #   mob_name = L
 # [../]
######################

######################  
  [./ACInterface4]
    type = ACInterface
    variable = eta4
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta4] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta4
      v = 'eta1 eta3 eta2 eta5 eta6 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta3 eta2 eta5 eta6 eta7'
[../]
###################################################################

  # Kernels for Allen-Cahn equation for eta5
  
######################
  [./deta5dt]
    type = TimeDerivative
    variable = eta5
  [../]
######################

######################  
  [./ACBulkF5]
    type = KKSMultiACBulkF
    variable  = eta5
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g5
    eta_i     = eta5
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta1 eta3 eta2 eta4 eta6 eta7'
    mob_name = L
  [../]
######################

######################
  [./ACBulkC5a]
    type = KKSMultiACBulkC
    variable  = eta5
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta5
    args      = 'eta1 eta3 eta2 eta4 eta6 eta7'
    mob_name = L
  [../]
######################
######################
 # [./ACBulkC5b]
 #   type = KKSMultiACBulkC
 #   variable  = eta2
 #   Fj_names  = 'F1 F2 F3 F2 F2'
 #   hj_names  = 'h1 h2 h3 h4 h5'
 #   cj_names  = 'c1b c2b c3b c2b c2b'
 #   eta_i     = eta5
 #   args      = 'eta1 eta3 eta2 eta4'
 #   mob_name = L
 # [../]
######################

######################  
  [./ACInterface5]
    type = ACInterface
    variable = eta5
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta5] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta5
      v = 'eta1 eta3 eta2 eta4 eta6 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta3 eta2 eta4 eta6 eta7'
[../]
##################################################################
# Kernels for Allen-Cahn equation for eta6
  
######################
  [./deta6dt]
    type = TimeDerivative
    variable = eta6
  [../]
######################

######################  
  [./ACBulkF6]
    type = KKSMultiACBulkF
    variable  = eta6
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g6
    eta_i     = eta6
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta1 eta3 eta2 eta4 eta5 eta7'
    mob_name = L
  [../]
######################

######################
  [./ACBulkC6a]
    type = KKSMultiACBulkC
    variable  = eta6
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta6
    args      = 'eta1 eta3 eta2 eta4 eta5 eta7'
    mob_name = L
  [../]
######################
######################
 # [./ACBulkC5b]
 #   type = KKSMultiACBulkC
 #   variable  = eta2
 #   Fj_names  = 'F1 F2 F3 F2 F2'
 #   hj_names  = 'h1 h2 h3 h4 h5'
 #   cj_names  = 'c1b c2b c3b c2b c2b'
 #   eta_i     = eta6
 #   args      = 'eta1 eta3 eta2 eta4'
 #   mob_name = L
 # [../]
######################

######################  
  [./ACInterface6]
    type = ACInterface
    variable = eta6
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta6] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta6
      v = 'eta1 eta3 eta2 eta4 eta5 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta3 eta2 eta4 eta5 eta7'
[../]
##################################################################
##################################################################
# Kernels for Allen-Cahn equation for eta7
  
######################
  [./deta7dt]
    type = TimeDerivative
    variable = eta7
  [../]
######################

######################  
  [./ACBulkF7]
    type = KKSMultiACBulkF
    variable  = eta7
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g7
    eta_i     = eta7
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta1 eta3 eta2 eta4 eta5 eta6'
    mob_name = L
  [../]
######################

######################
  [./ACBulkC7a]
    type = KKSMultiACBulkC
    variable  = eta7
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta7
    args      = 'eta1 eta3 eta2 eta4 eta5 eta6'
    mob_name = L
  [../]
######################
######################
 # [./ACBulkC5b]
 #   type = KKSMultiACBulkC
 #   variable  = eta2
 #   Fj_names  = 'F1 F2 F3 F2 F2'
 #   hj_names  = 'h1 h2 h3 h4 h5'
 #   cj_names  = 'c1b c2b c3b c2b c2b'
 #   eta_i     = eta7
 #   args      = 'eta1 eta3 eta2 eta4'
 #   mob_name = L
 # [../]
######################

######################  
  [./ACInterface7]
    type = ACInterface
    variable = eta7
    kappa_name = kappa
    mob_name = L
  [../]
##################################################################
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta7] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta7
      v = 'eta1 eta3 eta2 eta4 eta5 eta6'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta3 eta2 eta4 eta5 eta6'
[../]
##################################################################
# Kernels for Allen-Cahn equation for eta3

######################
  [./deta3dt]
    type = TimeDerivative
    variable = eta3
  [../]
######################

######################
  [./ACBulkF3]
    type = KKSMultiACBulkF
    variable  = eta3
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    gi_name   = g3
    eta_i     = eta3
    wi        = 5.0 #1.0
    args      = 'c1a c2a c3a eta2 eta1 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################


######################
  [./ACBulkC3a]
    type = KKSMultiACBulkC
    variable  = eta3
    Fj_names  = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names  = 'h1 h2 h3 h4 h5 h6 h7'
    cj_names  = 'c1a c2a c3a c2a c2a c2a c2a'
    eta_i     = eta3
    args      = 'eta2 eta1 eta4 eta5 eta6 eta7'
    mob_name = L
  [../]
######################

######################
#  [./ACBulkC3b]
#    type = KKSMultiACBulkC
#    variable  = eta3
#    Fj_names  = 'F1 F2 F3 F2 F2'
#    hj_names  = 'h1 h2 h3 h4 h5'
#    cj_names  = 'c1b c2b c3b c2b c2b'
#    eta_i     = eta3
#    args      = 'eta2 eta1 eta4 eta5'
#    mob_name = L
#  [../]
######################

######################
  [./ACInterface3]
    type = ACInterface
    variable = eta3
    kappa_name = kappa
    mob_name = L
  [../]
######################
##################################################################
# This kernel requires the model parameter m (mu) and the gamma parameter
###########################################################################
[./ACdfintdeta3] #L*m*(eta_i^3-eta_i+2*beta*eta_i*sum_j eta_j^2)
      type = ACGrGrMulti
      variable = eta3
      v = 'eta1 eta5 eta2 eta4 eta6 eta7'
      gamma_names = 'gamma gamma gamma gamma gamma gamma'
      mob_name = L
      args = 'eta1 eta5 eta2 eta4 eta6 eta7'
[../]
########################################################################################

[]

########################################################################################




########################################################################################

[AuxKernels]
[./bnds]
    type = BndsCalcAux
    variable = bnds
    var_name_base = eta
    op_num = 5 #2
    v = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7' #Not writing a variable here will put a 0 value on the eta value of the absentee
  [../]
############################################
  [./Energy_total]
    type = KKSMultiFreeEnergy
    Fj_names = 'F1 F2 F3 F2 F2 F2 F2'
    hj_names = 'h1 h2 h3 h4 h5 h6 h7'
    gj_names = 'g1 g2 g3 g4 g5 g6 g7'
    variable = Energy
    w = 1
    interfacial_vars =  'eta1  eta2  eta3 eta4 eta5 eta6 eta7'
    kappa_names =       'kappa kappa kappa kappa kappa kappa kappa'
  [../]
############################################
############################################
[./grains_hsquarec]
      type = SevenPhasesSumCdothsquare
      variable = gr_c
      var1 = ca
      h1_name = h1
      h2_name = h2
      h3_name = h3
      h4_name = h4
      h5_name = h5
      h6_name = h6
      h7_name = h7
[../]
[]

########################################################################################

########################################################################################
[Postprocessors]
    [./cu_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h1
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./imc1_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h2
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./sn_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h3
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./imc2_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h4
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./imc3_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h5
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./imc4_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h6
      execute_on = 'Initial TIMESTEP_END'
    [../]
    [./imc5_area_h]
      type = ElementIntegralMaterialProperty
      mat_prop = h7
      execute_on = 'Initial TIMESTEP_END'
    [../]

[]

########################################################################################

[Executioner]

############################################
#  type = Transient
#  solve_type = 'PJFNK'
#  petsc_options_iname = '-pc_type -sub_pc_type   -sub_pc_factor_shift_type'
#  petsc_options_value = 'asm       ilu            nonzero'
#  l_max_its = 100 #100 #30
#  nl_max_its = 50 #10
#  l_tol = 1.0e-4
#  nl_rel_tol = 1.0e-9 #1.0e-10
#  nl_abs_tol = 1.0e-10 #1.0e-11

#  #num_steps = 45 #2
#  #dt = 0.5
#  end_time=1.0E+010
  ############################################
#[./TimeStepper]
 #   ## Turn on time stepping
#    type = IterationAdaptiveDT
#    dt = 1.0E+01 #-02 #1.0E-02 #1.0E-1 #0.5 #1.00E+04 #06
#    cutback_factor = 0.7
#    growth_factor = 1.50 #1.5
#    optimal_iterations = 7
#    #num_steps = 55
#[../]
############################################
############################################
  type = Transient
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type -sub_pc_type   -sub_pc_factor_shift_type'
  petsc_options_value = 'asm       ilu            nonzero'
  l_max_its = 100 #100 #30
  nl_max_its = 50 #10
  l_tol = 1.0e-4
  nl_rel_tol = 1.0e-8 # 1.0e-10
  nl_abs_tol = 1.0e-9 # 1.0e-11

  #num_steps = 45 #2
  #dt = 0.5
  dtmax = 100000 #2500 #5000 #10000
  dtmin = 1 #250 #500
  end_time=1.0E+012 #10
  ############################################
[./TimeStepper]
    ## Turn on time stepping
    type = IterationAdaptiveDT
    dt =  200 #225 #1250 #100 #25 #250 #850 #1250 # 100 #250 #500 #750 #1000.0E+00 #5.0e-03  #1.0e+05 #best is 1.0e+05 # 1.0e+03 #1.0
    #dt = 10.0 #1.0E+01 #-02 #1.0E-02 #1.0E-1 #0.5 #1.00E+04 #06
    cutback_factor = 0.85 #0.9999 #0.95 #0.9999 #0.7 #0.9999 #0.7 # 0.9999 #0.7 # 0.9999 #0.9999 #0.95 #0.9 #0.7 #0.9999 #0.9 #0.7 #0.7
    growth_factor = 1.25 #1.5 # 1.0001 #1.5 # 1.0001 #1.5  #1.5 #1.50 #1.5
    optimal_iterations = 7 #2 #7
    #num_steps = 55
[../]
############################################
############################################
# adaptive mesh to resolve an interface
   [./Adaptivity]
     initial_adaptivity    = 3 #3 #3 #2 #3 #3 #2             # Number of times mesh is adapted to initial condition
     refine_fraction       = 0.7 #0.7           # Fraction of high error that will be refined
     coarsen_fraction      = 0.1           # Fraction of low error that will coarsened
     max_h_level           = 4 #3 #4 #4 #3 #2 #3 #3 #2 #3             # Max number of refinements used, starting from initial mesh (before uniform refinement)
     weight_names          = 'eta1 eta2 eta3 eta4 eta5 eta6 eta7'
    weight_values         = '1 1 1 1 1 1 1'
   [../]
[]

########################################################################################



########################################################################################

[Preconditioning]

############################################
  active = 'full'
  [./full]
    type = SMP
    full = true
  [../]
  [./mydebug]
    type = FDP
    full = true
  [../]
############################################

[]

########################################################################################



########################################################################################

[Outputs]

############################################
  exodus = true
  csv  = true
  interval = 100 #100 #10 #20 #100 #100 #1 #20 #10 #5 #1 #10 #5 #50 #1 #50 #20 #10
  checkpoint = true
############################################
 #[./my_checkpoint]
  #  type = Checkpoint
  #  num_files = 4
  #  interval = 10 #5
 # [../]

[]

########################################################################################


[Debug]
  show_var_residual_norms = true
[]
