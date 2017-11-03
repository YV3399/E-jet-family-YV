<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="http://jsbsim.sourceforge.net/JSBSim.xsl"?>
<fdm_config name="E170" version="2.0" release="ALPHA"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:noNamespaceSchemaLocation="http://jsbsim.sourceforge.net/JSBSim.xsd">

 <fileheader>
  <author> Aeromatic v 0.96 </author>
  <filecreationdate>2017-10-21</filecreationdate>
  <version>$Revision: 1.20 $</version>
  <description> Models a E170. </description>
 </fileheader>

<!--
  File:     E170.xml
  Inputs:
    name:          E170
    type:          two-engine transonic transport
    max weight:    79357.95 lb
    wing span:     85.306 ft
    length:        98.1019 ft
    wing area:     782.82796392 sq-ft
    gear type:     tricycle
    castering:     
    retractable?:  yes
    # engines:     2
    engine type:   turbine
    engine layout: wings
    yaw damper?    yes
  Outputs:
    wing loading:  101.37 lb/sq-ft
    payload:       10850.3 lbs
    CL-alpha:      4.4 per radian
    CL-0:          0.2
    CL-max:        1.2
    CD-0:          0.02
    K:             0.043

-->

 <metrics>
   <wingarea  unit="FT2">  782.83 </wingarea>
   <wingspan  unit="FT" >   85.31 </wingspan>
   <wing_incidence>          2.00 </wing_incidence>
   <chord     unit="FT" >    9.18 </chord>
   <htailarea unit="FT2">  195.71 </htailarea>
   <htailarm  unit="FT" >   44.15 </htailarm>
   <vtailarea unit="FT2">  156.57 </vtailarea>
   <vtailarm  unit="FT" >   44.15 </vtailarm>
   <location name="AERORP" unit="IN">
     <x> 647.47 </x>
     <y>   0.00 </y>
     <z>   0.00 </z>
   </location>
   <location name="EYEPOINT" unit="IN">
     <x>  82.41 </x>
     <y> -30.00 </y>
     <z>  70.00 </z>
   </location>
   <location name="VRP" unit="IN">
     <x>0</x>
     <y>0</y>
     <z>0</z>
   </location>
 </metrics>

 <mass_balance>
   <ixx unit="SLUG*FT2">    164291 </ixx>
   <iyy unit="SLUG*FT2">    501992 </iyy>
   <izz unit="SLUG*FT2">    642787 </izz>
   <emptywt unit="LBS" >     46526 </emptywt>
   <location name="CG" unit="IN">
     <x> 647.47 </x>
     <y>   0.00 </y>
     <z> -29.43 </z>
   </location>
   <pointmass name="Payload">
    <description> 10850 LBS + full (21982 LBS) fuel should bring model up to entered max weight</description>
    <weight unit="LBS">   5425.1 </weight>
    <location name="POINTMASS" unit="IN">
      <x> 647.47 </x>
      <y>   0.00 </y>
      <z> -29.43 </z>
    </location>
  </pointmass> 
 </mass_balance>

 <ground_reactions>

<!-- Nose Gear Contact Point -->
  <contact type="BOGEY" name="NOSE_GEAR">
   <location unit="IN">
     <x> -425.52 </x>
     <y> 0.00 </y>
     <z> -89.832 </z>
   </location>
   <static_friction>  0.80 </static_friction>
   <dynamic_friction> 0.50 </dynamic_friction>
   <rolling_friction> 0.02 </rolling_friction>
	<spring_coeff unit="LBS/FT"> 180000 </spring_coeff>
	<damping_coeff unit="LBS/FT/SEC"> 33957 </damping_coeff>
   <max_steer unit="DEG"> 70 </max_steer>
   <brake_group>NONE</brake_group>
   <retractable>1</retractable>
</contact>

<!-- Left Main Gear Contact Point -->
  <contact type="BOGEY" name="LEFT_MAIN">
   <location unit="IN">
     <x> -10.43 </x>
     <y> -101.258 </y>
     <z> -93.772 </z>
   </location>
   <static_friction>  0.80 </static_friction>
   <dynamic_friction> 0.50 </dynamic_friction>
   <rolling_friction> 0.02 </rolling_friction>
	<spring_coeff unit="LBS/FT"> 180000 </spring_coeff>
	<damping_coeff unit="LBS/FT/SEC"> 33957 </damping_coeff>
   <max_steer unit="DEG">0</max_steer>
   <brake_group>LEFT</brake_group>
   <retractable>1</retractable>
</contact>

<!-- Right Main Gear Contact Point -->
  <contact type="BOGEY" name="RIGHT_MAIN">
   <location unit="IN">
     <x> -10.43 </x>
     <y> 101.258 </y>
     <z> -93.772 </z>
   </location>
   <static_friction>  0.80 </static_friction>
   <dynamic_friction> 0.50 </dynamic_friction>
   <rolling_friction> 0.02 </rolling_friction>
	<spring_coeff unit="LBS/FT"> 180000 </spring_coeff>
	<damping_coeff unit="LBS/FT/SEC"> 33957 </damping_coeff>
   <max_steer unit="DEG">0</max_steer>
   <brake_group>RIGHT</brake_group>
   <retractable>1</retractable>
</contact>

<!-- Left Wing Tip Contact Point -->
  <contact type="STRUCTURE" name="LEFT_WING_TIP">
    <location unit="IN">
     <x> 102.44 </x>
     <y> -490.924 </y>
     <z> 10.64 </z>
    </location>
    <static_friction>  0.9 </static_friction>
    <dynamic_friction> 0.8 </dynamic_friction>
    <spring_coeff unit="LBS/FT">      200000.00 </spring_coeff>
    <damping_coeff unit="LBS/FT/SEC"> 10000.00 </damping_coeff>
    <brake_group> NONE </brake_group>
    <retractable>0</retractable>
</contact>

<!-- Right Wing Tip Contact Point -->
  <contact type="STRUCTURE" name="RIGHT_WING_TIP">
    <location unit="IN">
     <x> 102.44 </x>
     <y> 490.924 </y>
     <z> 10.64 </z>
    </location>
    <static_friction>  0.9 </static_friction>
    <dynamic_friction> 0.8 </dynamic_friction>
    <spring_coeff unit="LBS/FT">      200000.00 </spring_coeff>
    <damping_coeff unit="LBS/FT/SEC"> 10000.00 </damping_coeff>
    <brake_group> NONE </brake_group>
    <retractable>0</retractable>
</contact>

<!-- Tail (in case of a tail strike) Contact Point -->
  <contact type="STRUCTURE" name="TAIL_STRIKE">
    <location unit="IN">
     <x> 543.6938 </x>
     <y> 0 </y>
     <z> 45.62914 </z>
    </location>
    <static_friction>  0.95 </static_friction>
    <dynamic_friction> 0.9 </dynamic_friction>
    <spring_coeff unit="LBS/FT">      200000.00 </spring_coeff>
    <damping_coeff unit="LBS/FT/SEC"> 10000.00 </damping_coeff>
    <brake_group> NONE </brake_group>
    <retractable>0</retractable>
</contact>

<!-- Nose (used for Ditching) Contact Point -->
  <contact type="STRUCTURE" name="TAIL_STRIKE">
    <location unit="IN">
     <x> -541.75 </x>
     <y> 0 </y>
     <z> -28.762 </z>
    </location>
    <static_friction>  0.95 </static_friction>
    <dynamic_friction> 0.9 </dynamic_friction>
    <spring_coeff unit="LBS/FT">      200000.00 </spring_coeff>
    <damping_coeff unit="LBS/FT/SEC"> 10000.00 </damping_coeff>
    <brake_group> NONE </brake_group>
    <retractable>0</retractable>
</contact>
 </ground_reactions>

 <propulsion>

   <engine file="GE_CF34-8E">
    <location unit="IN">
      <x> 647.47 </x>
      <y> -170.61 </y>
      <z> -40.00 </z>
    </location>
    <orient unit="DEG">
      <pitch> 0.00 </pitch>
      <roll>  0.00 </roll>
      <yaw>   0.00 </yaw>
    </orient>
    <feed>0</feed>
    <thruster file="direct">
     <location unit="IN">
       <x> 647.47 </x>
       <y> -170.61 </y>
       <z> -40.00 </z>
     </location>
     <orient unit="DEG">
       <pitch> 0.00 </pitch>
       <roll>  0.00 </roll>
       <yaw>   0.00 </yaw>
     </orient>
    </thruster>
  </engine>

   <engine file="GE_CF34-8E">
    <location unit="IN">
      <x> 647.47 </x>
      <y> 170.61 </y>
      <z> -40.00 </z>
    </location>
    <orient unit="DEG">
      <pitch> 0.00 </pitch>
      <roll>  0.00 </roll>
      <yaw>   0.00 </yaw>
    </orient>
    <feed>1</feed>
    <thruster file="direct">
     <location unit="IN">
       <x> 647.47 </x>
       <y> 170.61 </y>
       <z> -40.00 </z>
     </location>
     <orient unit="DEG">
       <pitch> 0.00 </pitch>
       <roll>  0.00 </roll>
       <yaw>   0.00 </yaw>
     </orient>
    </thruster>
  </engine>

  <tank type="FUEL" number="0">
     <location unit="IN">
       <x> 647.47 </x>
       <y>   0.00 </y>
       <z> -29.43 </z>
     </location>
     <capacity unit="LBS"> 7327.38 </capacity>
     <contents unit="LBS"> 3663.69 </contents>
  </tank>

  <tank type="FUEL" number="1">
     <location unit="IN">
       <x> 647.47 </x>
       <y>   0.00 </y>
       <z> -29.43 </z>
     </location>
     <capacity unit="LBS"> 7327.38 </capacity>
     <contents unit="LBS"> 3663.69 </contents>
  </tank>

  <tank type="FUEL" number="2">
     <location unit="IN">
       <x> 647.47 </x>
       <y>   0.00 </y>
       <z> -29.43 </z>
     </location>
     <capacity unit="LBS"> 7327.38 </capacity>
     <contents unit="LBS"> 3663.69 </contents>
  </tank>

 </propulsion>

 <flight_control name="FCS: E170">

  <channel name="Pitch">

   <summer name="Pitch Trim Sum">
      <input>fcs/elevator-cmd-norm</input>
      <input>fcs/pitch-trim-cmd-norm</input>
      <clipto>
        <min> -1 </min>
        <max>  1 </max>
      </clipto>
   </summer>

   <aerosurface_scale name="Elevator Control">
      <input>fcs/pitch-trim-sum</input>
      <range>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </range>
      <output>fcs/elevator-pos-rad</output>
   </aerosurface_scale>

   <aerosurface_scale name="elevator normalization">
      <input>fcs/elevator-pos-rad</input>
      <domain>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </domain>
      <range>
        <min> -1 </min>
        <max>  1 </max>
      </range>
      <output>fcs/elevator-pos-norm</output>
   </aerosurface_scale>

  </channel>

  <channel name="Roll">

   <summer name="Roll Trim Sum">
      <input>fcs/aileron-cmd-norm</input>
      <input>fcs/roll-trim-cmd-norm</input>
      <clipto>
        <min> -1 </min>
        <max>  1 </max>
      </clipto>
   </summer>

   <aerosurface_scale name="Left Aileron Control">
      <input>fcs/roll-trim-sum</input>
      <range>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </range>
      <output>fcs/left-aileron-pos-rad</output>
   </aerosurface_scale>

   <aerosurface_scale name="Right Aileron Control">
      <input>fcs/roll-trim-sum</input>
      <range>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </range>
      <output>fcs/right-aileron-pos-rad</output>
   </aerosurface_scale>

   <aerosurface_scale name="left aileron normalization">
      <input>fcs/left-aileron-pos-rad</input>
      <domain>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </domain>
      <range>
        <min> -1 </min>
        <max>  1 </max>
      </range>
      <output>fcs/left-aileron-pos-norm</output>
   </aerosurface_scale>

   <aerosurface_scale name="right aileron normalization">
      <input>fcs/right-aileron-pos-rad</input>
      <domain>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </domain>
      <range>
        <min> -1 </min>
        <max>  1 </max>
      </range>
      <output>fcs/right-aileron-pos-norm</output>
   </aerosurface_scale>

  </channel>

  <property value="1">fcs/yaw-damper-enable</property>
  <channel name="Yaw">

   <summer name="Rudder Command Sum">
      <input>fcs/rudder-cmd-norm</input>
      <input>fcs/yaw-trim-cmd-norm</input>
      <clipto>
        <min> -1 </min>
        <max>  1 </max>
      </clipto>
   </summer>

   <scheduled_gain name="Yaw Damper Rate">
      <input>velocities/r-aero-rad_sec</input>
      <table>
        <independentVar lookup="row">velocities/ve-kts</independentVar>
         <tableData>
            30     0.00
            60     2.00
         </tableData>
      </table>
      <gain>fcs/yaw-damper-enable</gain>
   </scheduled_gain>

   <summer name="Rudder Sum">
      <input>fcs/rudder-command-sum</input>
      <input>fcs/yaw-damper-rate</input>
      <clipto>
        <min> -1.1 </min>
        <max>  1.1 </max>
      </clipto>
   </summer>

   <aerosurface_scale name="Rudder Control">
      <input>fcs/rudder-sum</input>
      <domain>
        <min> -1.1 </min>
        <max>  1.1 </max>
      </domain>
      <range>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </range>
      <output>fcs/rudder-pos-rad</output>
   </aerosurface_scale>

   <aerosurface_scale name="rudder normalization">
      <input>fcs/rudder-pos-rad</input>
      <domain>
        <min> -0.35 </min>
        <max>  0.35 </max>
      </domain>
      <range>
        <min> -1 </min>
        <max>  1 </max>
      </range>
      <output>fcs/rudder-pos-norm</output>
   </aerosurface_scale>

  </channel>

  <channel name="Slats">
	  
	  <!--Set slats according to http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf page 4-->
          <fcs_function name="Slats Cmd">
             <function>
		     <quotient>
                      <table>
                         <independentVar>/controls/flight/flaps</independentVar>
                         <tableData>
                            0      0
                            0.1      15
			    0.2	   15
			    0.3      15
			    0.4      25
			    0.5      25
			    0.6      25
                         </tableData>
                      </table>   
		      <value>25</value>
	      </quotient>
             </function>
             <output>fcs/slat-cmd-int-norm</output>   
          </fcs_function>  
	  
   <kinematic name="Slats Control">
     <input>fcs/slat-cmd-int-norm</input>
     <traverse>
                <setting>
                    <position>0.0</position>
                    <time>0.0000</time>
                </setting>
                <setting>
                    <position>15</position>
                    <time>2.0000</time>
                </setting>
                <setting>
                    <position>25</position>
                    <time>2.0000</time>
                </setting>
     </traverse>
     <output>fcs/slat-pos-deg</output>
   </kinematic>

   <aerosurface_scale name="slat normalization">
      <input>fcs/slat-pos-deg</input>
      <domain>
        <min>  0 </min>
        <max> 25 </max>
      </domain>
      <range>
        <min> 0 </min>
        <max> 1 </max>
      </range>
      <output>fcs/slat-pos-norm</output>
   </aerosurface_scale>

  </channel>
  
  
	  

  <channel name="Flaps">
	  
             
          <!-- Set flaps according to http://www.smartcockpit.com/docs/Embraer_190-Flight_Controls.pdf page 4-->
          <fcs_function name="Flaps Cmd">
             <function>
		     <quotient>
                      <table>
                         <independentVar>/controls/flight/flaps</independentVar>
                         <tableData>
                            0      0
                            0.1      7
			    0.2	   10
			    0.3      20
			    0.4      20
			    0.5      20
			    0.6      37
                         </tableData>
                      </table>   
		      <value>37</value>
	      </quotient>
             </function>
             <output>fcs/flap-cmd-int-norm</output>   
          </fcs_function>  
	  
   <kinematic name="Flaps Control">
     <input>fcs/flap-cmd-int-norm</input>
     <traverse>
                <setting>
                    <position>0.0</position>
                    <time>0.0000</time>
                </setting>
                <setting>
                    <position>7</position>
                    <time>1.0000</time>
                </setting>
                <setting>
                    <position>10.0000</position>
                    <time>1.0000</time>
                </setting>
                <setting>
                    <position>20.0000</position>
                    <time>1.0000</time>
                </setting>
                <setting>
                    <position>20.0000</position>
                    <time>1.0000</time>
                </setting>
                <setting>
                    <position>20.0000</position>
                    <time>1.0000</time>
                </setting>
                <setting>
                    <position>37.0000</position>
                    <time>1.0000</time>
                </setting>
     </traverse>
     <output>fcs/flap-pos-deg</output>
   </kinematic>

   <aerosurface_scale name="flap normalization">
      <input>fcs/flap-pos-deg</input>
      <domain>
        <min>  0 </min>
        <max> 37 </max>
      </domain>
      <range>
        <min> 0 </min>
        <max> 1 </max>
      </range>
      <output>fcs/flap-pos-norm</output>
   </aerosurface_scale>

  </channel>

  <channel name="Landing Gear">
   <kinematic name="Gear Control">
     <input>gear/gear-cmd-norm</input>
     <traverse>
       <setting>
          <position> 0 </position>
          <time>     0 </time>
       </setting>
       <setting>
          <position> 1 </position>
          <time>     5 </time>
       </setting>
     </traverse>
     <output>gear/gear-pos-norm</output>
   </kinematic>

  </channel>

  <channel name="Speedbrake">
   <kinematic name="Speedbrake Control">
     <input>fcs/speedbrake-cmd-norm</input>
     <traverse>
       <setting>
          <position> 0 </position>
          <time>     0 </time>
       </setting>
       <setting>
          <position> 1 </position>
          <time>     1 </time>
       </setting>
     </traverse>
     <output>fcs/speedbrake-pos-norm</output>
   </kinematic>

  </channel>

 </flight_control>

 <aerodynamics>

  <axis name="LIFT">

    <function name="aero/force/Lift_alpha">
      <description>Lift due to alpha</description>
      <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <table>
            <independentVar lookup="row">aero/alpha-rad</independentVar>
            <tableData>
              -0.20 -0.680
               0.00  0.200
               0.23  1.200
               0.60  0.600
            </tableData>
          </table>
      </product>
    </function>

    <function name="aero/force/Lift_flap">
       <description>Delta Lift due to flaps</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>fcs/flap-pos-deg</property>
           <value> 0.05000 </value>
       </product>
    </function>

    <function name="aero/force/Lift_speedbrake">
       <description>Delta Lift due to speedbrake</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>fcs/speedbrake-pos-norm</property>
           <value>-0.1</value>
       </product>
    </function>

    <function name="aero/force/Lift_elevator">
       <description>Lift due to Elevator Deflection</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>fcs/elevator-pos-rad</property>
           <value>0.2</value>
       </product>
    </function>

  </axis>

  <axis name="DRAG">

    <function name="aero/force/Drag_basic">
       <description>Drag at zero lift</description>
       <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <table>
            <independentVar lookup="row">aero/alpha-rad</independentVar>
            <tableData>
             -1.57    1.500
             -0.26    0.026
              0.00    0.020
              0.26    0.026
              1.57    1.500
            </tableData>
          </table>
       </product>
    </function>

    <function name="aero/force/Drag_induced">
       <description>Induced drag</description>
         <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>aero/cl-squared</property>
           <value>0.043</value>
         </product>
    </function>

    <function name="aero/force/Drag_mach">
       <description>Drag due to mach</description>
        <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <table>
            <independentVar lookup="row">velocities/mach</independentVar>
            <tableData>
                0.00      0.000
                0.79      0.000
                1.10      0.023
                1.80      0.015
            </tableData>
          </table>
        </product>
    </function>

    <function name="aero/force/Drag_flap">
       <description>Drag due to flaps</description>
         <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>fcs/flap-pos-deg</property>
           <value> 0.00197 </value>
         </product>
    </function>

    <function name="aero/force/Drag_gear">
       <description>Drag due to gear</description>
         <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>gear/gear-pos-norm</property>
           <value>0.015</value>
         </product>
    </function>

    <function name="aero/force/Drag_speedbrake">
       <description>Drag due to speedbrakes</description>
         <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>fcs/speedbrake-pos-norm</property>
           <value>0.02</value>
         </product>
    </function>

    <function name="aero/force/Drag_beta">
       <description>Drag due to sideslip</description>
       <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <table>
            <independentVar lookup="row">aero/beta-rad</independentVar>
            <tableData>
              -1.57    1.230
              -0.26    0.050
               0.00    0.000
               0.26    0.050
               1.57    1.230
            </tableData>
          </table>
       </product>
    </function>

    <function name="aero/force/Drag_elevator">
       <description>Drag due to Elevator Deflection</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <abs><property>fcs/elevator-pos-norm</property></abs>
           <value>0.04</value>
       </product>
    </function>

  </axis>

  <axis name="SIDE">

    <function name="aero/force/Side_beta">
       <description>Side force due to beta</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>aero/beta-rad</property>
           <value>-1</value>
       </product>
    </function>

  </axis>

  <axis name="ROLL">

    <function name="aero/moment/Roll_beta">
       <description>Roll moment due to beta</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>aero/beta-rad</property>
           <value>-0.1</value>
       </product>
    </function>

    <function name="aero/moment/Roll_damp">
       <description>Roll moment due to roll rate</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>aero/bi2vel</property>
           <property>velocities/p-aero-rad_sec</property>
           <value>-0.4</value>
       </product>
    </function>

    <function name="aero/moment/Roll_yaw">
       <description>Roll moment due to yaw rate</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>aero/bi2vel</property>
           <property>velocities/r-aero-rad_sec</property>
           <value>0.15</value>
       </product>
    </function>

    <function name="aero/moment/Roll_aileron">
       <description>Roll moment due to aileron</description>
       <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <property>metrics/bw-ft</property>
          <property>fcs/left-aileron-pos-rad</property>
          <value>0.1</value>
       </product>
    </function>

    <function name="aero/moment/Roll_rudder">
       <description>Roll moment due to rudder</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>fcs/rudder-pos-rad</property>
           <value>0.01</value>
       </product>
    </function>

  </axis>

  <axis name="PITCH">

    <function name="aero/moment/Pitch_alpha">
       <description>Pitch moment due to alpha</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/cbarw-ft</property>
           <property>aero/alpha-rad</property>
           <value>-0.6</value>
       </product>
    </function>

    <function name="aero/moment/Pitch_elevator">
       <description>Pitch moment due to elevator</description>
       <product>
          <property>aero/qbar-psf</property>
          <property>metrics/Sw-sqft</property>
          <property>metrics/cbarw-ft</property>
          <property>fcs/elevator-pos-rad</property>
          <table>
            <independentVar lookup="row">velocities/mach</independentVar>
            <tableData>
              0.0     -1.200
              2.0     -0.300
            </tableData>
          </table>
       </product>
    </function>

    <function name="aero/moment/Pitch_damp">
       <description>Pitch moment due to pitch rate</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/cbarw-ft</property>
           <property>aero/ci2vel</property>
           <property>velocities/q-aero-rad_sec</property>
           <value>-17</value>
       </product>
    </function>

    <function name="aero/moment/Pitch_alphadot">
       <description>Pitch moment due to alpha rate</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/cbarw-ft</property>
           <property>aero/ci2vel</property>
           <property>aero/alphadot-rad_sec</property>
           <value>-6</value>
       </product>
    </function>

  </axis>

  <axis name="YAW">

    <function name="aero/moment/Yaw_beta">
       <description>Yaw moment due to beta</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>aero/beta-rad</property>
           <value>0.12</value>
       </product>
    </function>

    <function name="aero/moment/Yaw_damp">
       <description>Yaw moment due to yaw rate</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>aero/bi2vel</property>
           <property>velocities/r-aero-rad_sec</property>
           <value>-0.15</value>
       </product>
    </function>

    <function name="aero/moment/Yaw_rudder">
       <description>Yaw moment due to rudder</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>fcs/rudder-pos-rad</property>
           <value>-0.1</value>
       </product>
    </function>

    <function name="aero/moment/Yaw_aileron">
       <description>Adverse yaw</description>
       <product>
           <property>aero/qbar-psf</property>
           <property>metrics/Sw-sqft</property>
           <property>metrics/bw-ft</property>
           <property>fcs/left-aileron-pos-rad</property>
           <value>0</value>
       </product>
    </function>

  </axis>

 </aerodynamics>

 <external_reactions>
 </external_reactions>

</fdm_config>