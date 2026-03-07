#
# Test the split parsed function free enery Cahn-Hilliard Bulk kernel
# The free energy used here has the same functional form as the SplitCHPoly kernel
# If everything works, the output of this test should replicate the output
# of marmot/tests/chpoly_test/CHPoly_Cu_Split_test.i (exodiff match)
#

[Mesh]
  #file = Mesh_1alni.unv # 40 * 40 mesh
  #file = Mesh_2alni.unv # 100 * 100 mesh
  #file = Mesh_3.unv # 100 * 100 mesh
  #file = Mesh_1alni-tri.unv # 125  fluid involving liquid spread, 25 solid triangular mesh and surrounding fluid
  file = Mesh_2material-triangle.unv # 200  fluid involving liquid spread, 50 solid triangular mesh and surrounding fluid
  #the numbers should be verified from the 
  #unv mesh format to be represented for a 
  #particular block and boundary of the geometry
  #The random BC ids 7 and 48 are written here
  #to highlight the role of verification from within
  #the file
  #That is the numbers 1, 2 ,3 , 7 and 48 are obtained from the mesh
  block_id = '1 2 3 4' # These numbers were reserved for first group selection for face, and new faces start from 1,2, [ 3,4],5,6,7,8 
  #block_id = '9 10'
  block_name = 'Face_fleft4 Face_solid5 Face_fcenter6 Face_fright7'
  boundary_id = '5 6 7 8 9 10 11 12 13 14 15 16' # These numbers were chosen for previous grouping which was deleted to select new  mesh edges in salome
  #boundary_id = '11  12 13 14 15 16 17'
  boundary_name = 'Edge_sleft1 Edge_fleft2 Edge_fleft3 Edge_finterface4 Edge_ftop5 Edge_sbottom6 Edge_interface7 Edge_finterface8 Edge_ftop9 Edge_sright10 Edge_fright11 Edge_fright12'
[]

[Variables]
  [./c]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
      type = FunctionIC
      #
      # Note: this initial conditions sets up a _sharp_ interface. Ideally
      # we should start with a smooth interface with a width consistent
      # with the kappa parameter supplied for the given interface.
      # R_original = 1336.5 um, scaled r= R_0/5 = 267.30
      # Make the circle touch the surface more by lowering the k in circle center (h,k)
      function = 'r:=sqrt((x-8.1)^2+(y-3.5)^2); (0.8841)*if(y>=0&y<=2.0,1,0)+1.0*if(y>=0&y<=2.0,0,if(r>1.8,0,1))-1.0*if(y>=0&y<=2.0,0,if(r<1.8,0,1))'
      #function = 'r:=sqrt((x-0.5)^2+(y-0.4)^2); (0.8)*if(y>=0&y<=0.2,1,0)+1.0*if(y>=0&y<=0.2,0,if(r>0.3,0,1))-1.0*if(y>=0&y<=0.2,0,if(r<0.3,0,1))'
      #function = 'r:=sqrt(x^2+y^2);if(r<=4,1,0)'
      #function = 'r:=sqrt((x-0.5)^2+(y-0.5)^2); (0.8)*if(y>=0&y<=0.2,1,0)+1.0*if(y>=0&y<=0.2,0,if(r>0.3,0,1))-1.0*if(y>=0&y<=0.2,0,if(r<0.3,0,1))'
      #function = 'r:=sqrt((x-0.5)^2+(y-0.3)^2); (1.0)*if(y>=0&y<=0.3,1,0)+1.0*if(y>=0&y<=0.3,0,if(r>0.3,0,1))-1.0*if(y>=0&y<=0.3,0,if(r<0.3,0,1))'
      # the initial composition is kept in different in solid to create different color
    [../]
    #
    # We set up a smooth cradial concentrtaion gradient
    # The concentration will quickly change to adapt to the preset order
    # parameters eta1, eta2, and eta3
    #
    #[./InitialCondition]
     # type = SmoothCircleIC
     # x1 = 0.0
     # y1 = 0.0
     # radius = 5.0
     # invalue = 1.0
     # outvalue = 0.01
     # int_width = 10.0
    #[../]
    #scaling=1.0e-08
   #scaling=1.0E+18
   #scaling=1.0E+09
  [../]
  [./w]
    order = FIRST
    family = LAGRANGE
    #scaling=1.0E-06
    #scaling=1.0E-06
    #scaling=1.0E+04
  [../]
[]

[Kernels]
  [./c_res]
    type = SplitCHParsed
    variable = c
    f_name = F
    kappa_name = kappa_c
    w = w
  [../]
  [./w_res]
    type = SplitCHWRes
    variable = w
    mob_name = M
  [../]
  [./time]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]
[]

[BCs]
  #[./Periodic]
    #[./All]
      #auto_direction = 'x y'
     # auto_direction = 'x '
     # variable = 'c'
   # [../]
  #[../]
  [./dirichlet1]
      type = DirichletBC
      #  #boundary = 'bottom' 
       boundary = 'Edge_sbottom6'
       variable = 'c'
       value = 1.0 #0.2 #0.8841
   [../]
   #[./dirichlet2]
     #  type = DirichletBC
     #   #boundary = 'top' 
     #   boundary = 'Edge_ftop5'
     #   variable = 'c'
     #   value = -1.0
  # [../]
[]

[Materials]
  [./pfmobility]
    type = GenericConstantMaterial
    prop_names  = 'Pseudo_M kappa_c'
    #prop_values = '1e-4 0.7' # Decrease mobility and increase kappa
    #prop_values = '1e-2 0.7' # Increase mobility and kappa
    #prop_values = '1e-4 0.5' # Decrease mobility and increase kappa
    #prop_values = '1.0 0.9' # Increase mobility and increase kappa
    #prop_values = '1.0E-02 2.0' 
    #prop_values = '1.0E-05 5.25E-03' 
    #prop_values = '1.0E-04 5.25E-03' 
    #prop_values = '1.0E-03 5.25E-04' 
    prop_values = '1.0E-02 5.25E-02' 
    #prop_values = '1e-3 0.1' #Original test file
    block = '1 2 3 4 '
  [../]

   [./CHMobility] # composition dependent mobility or CahnHilliard Mobility
    type = DerivativeParsedMaterial
    f_name = M
    #function = '2.50E-2*(tanh(4*c+1.5)+1.0)' #
    function = '1.0E-03*(tanh(4*c+1.5)+1.0)' #Yuryev2016 _MSMSAE, works for Mesh_1, k = 5.25E-04
    #function = '1.0E-2*(c+1)^2/4'
    ##function = '1.0*0.5*(c-0.80)^2'
    outputs = exodus
    args = 'c'
    block = '1 2 3 4' 
  [../]

   [./free_energy_solid]
    type = DerivativeParsedMaterial
    f_name = F
    args = 'c'
    constant_names       = 'barr_height  A  D'
    constant_expressions = '0.5          0.2 1.0'
    #constant_expressions = '0.5          1.0 1.0'
    function = 1.0*barr_height*(c-A)^2
    outputs = exodus
    derivative_order = 2
    block = '2 '
  [../]

  [./free_energy_fluid]
    type = DerivativeParsedMaterial
    f_name = F
    args = 'c'
    constant_names       = 'barr_height  B  D'
    constant_expressions = '0.25          1.0 1.0'
    function = 1.0*barr_height*(c^2-B)^2
    outputs = exodus
    derivative_order = 2
    block = '1 3 4'
  [../]

 
[]

[Preconditioning]
  # active = ' '
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  scheme = bdf2

  solve_type = 'NEWTON'
  petsc_options_iname = -pc_type
  petsc_options_value = lu

  l_max_its = 30
  l_tol = 1.0e-4
  nl_rel_tol = 1.0e-10
  start_time = 0.0
  num_steps = 500 #300  #100 #15000 #600
  
   dt = 1.0E-01 #10.0
  #dt = 10.0
  #dt = 1.0E-02
  #dt = 1.0E-04
  #dt = 1.0E-03
  #dt = 10
[]

[Debug]
  # show_var_residual_norms = true
  show_var_residual_norms = true
  show_material_props = false
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  interval=100 #100 #10 #5 #1 #7 #10 #5 #20
  [./table]
    type = CSV
    delimiter = ' '
  [../]
  [./my_checkpoint]
    type = Checkpoint
    num_files = 4
    interval =100 #100 #10 #5 #1 #7 #10  # 300
  [../]
[]
#
#[Outputs]
#  exodus = true
#[]
