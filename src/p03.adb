---------------------------------------------------------
------------------PARALLEL PROGRAMMING-------------------
-------------------COURSE WORK PART 2--------------------
----       --ADA. SEMAPHORES. PROTECTED UNITS--     -----
----              MA = MB*MC + MO*ME*a              -----
---------------------------------------------------------
-------------     MAIN MODULE PRG2     ------------------
---------------------------------------------------------
-----------------CREATED ON 20.03.2016-------------------
----------------BY OLEG PEDORENKO, IP-31-----------------
---------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Real_Time;      use Ada.Real_Time;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Data;

procedure p03 is

  N: Integer := 8;
  P: Integer := 2;
  H: Integer := 4;

  
begin
  --Read N and P from command line
  if(Argument_Count > 0) then 
    N := Integer'Value(Argument(1));
  end if;  
  if(Argument_Count > 1) then 
    P := Integer'Value(Argument(2));
  end if;  
  H := Integer(Float'Ceiling(Float(N)/Float(P)));
  
  declare  
    -- Types
    package Data_S is new Data(N, 100); use Data_S;
    subtype Range_H is Integer range 1..H;
    subtype Range_P is Integer range 1..P;
    subtype Range_2P is Integer range 2..P;
        
    -- Task type for T1 (Task that enters data)
    task type T1 is
      pragma Storage_Size(100000000);
    end T1;
    
    task type TX(I: Integer) is
      pragma Storage_Size(100000000);
      entry Task_Range(First, Last: in Integer);
      entry Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar);
      entry Result(r_MAh: out Proto_Matrix);
    end TX;

    T1_T: access T1;
    TX_Arr: array(Range_2P) of access TX;
    
    task body T1 is
      B, E: Integer;
      MA, MB, MC, MO, ME: Matrix;
      a: Scalar;
      Sum1, Sum2: Scalar;
        -- -- Calculate MAh
        -- procedure Calculate
          -- (MBa, MCha, MOa, MEha: Proto_Matrix; 
          -- aa: Scalar; 
          -- MAha: out Proto_Matrix) is
          -- Sum1, Sum2: Scalar;
        -- begin
          -- Put_Line("Enter: Calculate procedure for T1");
          -- for I in MBa'Range loop
            -- for J in MCha'Range loop
              -- Put(I); Put(J); Put_Line("");
              -- Sum1 := 0.0;
              -- Sum2 := 0.0;
              -- for K in MBa'Range loop
                -- Sum1 := Sum1 + (MBa(I)(K) * MCha(K)(J)); --MB * MCh
                -- Sum2 := Sum2 + (MOa(I)(K) * MEha(K)(J)); -- MO * MEh
              -- end loop;
              -- MAha(I)(J) := Sum1 + Sum2 * aa; -- Sum1 + Sum2 * aa;
            -- end loop;
          -- end loop;
        -- end;
    begin
      Put_Line("Task T1 started");
      --Initialize MA
      Fill(MA);
      --Enter MB, MC, MO, ME, a
      Put_Line("MB =   "); Input(MB); 
      Put_Line("MC =   "); Input(MC); 
      Put_Line("MO =   "); Input(MO); 
      Put_Line("ME =   "); Input(ME);      
      Put_Line("a =    "); Input(a); Put(a); Put_Line("");      
      -- Надсилання даних по задачах;
      for I in Range_2P loop
        Put(I); Put_Line("");
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;    
        Put(B); Put(E); Put_Line("");
        TX_Arr(I).Data(MB, MC(B..E), MO, ME(B..E), a);
      end loop;
      -- Обчислення даних;
      -- Calculate(MB, MC(Range_H), MO, ME(Range_H), a, MA(Range_H));
      ---------
      begin
        Put_Line("Enter: Calculate procedure for T1");
        -- for I in MB'Range loop
          -- for J in MC(Range_H)'Range loop
            -- Sum1 := 0.0;
            -- Sum2 := 0.0;
            -- for K in MB'Range loop
              -- Sum1 := Sum1 + (MB(I)(K) * MC(Range_H)(K)(J)); --MB * MCh
              -- Sum2 := Sum2 + (MO(I)(K) * ME(Range_H)(K)(J)); -- MO * MEh
          -- end loop;
            -- MA(Range_H)(I)(J) := Sum1 + Sum2 * a; -- Sum1 + Sum2 * aa;
          -- end loop;
        -- end loop;
        Output(MC(Range_H));
        Put_Line("Exit: Calculate procedure for T1");    
      end;      
      ---------
      Put_Line("After calculaiton");
      -- Прийом даних;
      for I in Range_2P loop
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;       
        TX_Arr(I).Result(MA(B..E));
      end loop;      
      -- Виведення результату;
      Put_Line("MA =   "); Output(MA);
      Put_Line("Task T1 finished");
    end T1;
    
    task body TX is
      B, E: Integer;
    begin
      Put_Line("Task T" & Integer'Image(I) &" started");
      accept Task_Range(First, Last: in Integer) do
        B := First;
        E := Last;
      end Task_Range;
      declare 
        -- Types
        subtype Range_T is Integer range B..E;
        -- Vars
        l_MB,  l_MO: Matrix;
        l_MCh, l_MEh: Proto_Matrix(Range_T);
        l_MAh: Proto_Matrix(Range_T);
        l_a: Scalar;
        Sum1, Sum2: Scalar;
      begin
        -- Прийом даних з Т1
        accept Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar) do
          l_MB := d_MB;
          l_MCh := d_MCh;
          l_MO := d_MO;
          l_MEh := d_MEh;
          l_a := d_a;
          Put_Line("Accepted Data");
        end Data;
        -- Обчислення МАн
        -- Calculate(l_MB, l_MO, l_MCh, l_MEh, l_a, l_MAh);
        ------
        begin
          Put_Line("Enter: Calculate procedure for T"& Integer'Image(I));
          -- for I in l_MB'Range loop
            -- for J in l_MCh'Range loop
              -- Sum1 := 0.0;
              -- Sum2 := 0.0;
              -- for K in l_MB'Range loop
                -- Sum1 := Sum1 + (l_MB(I)(K) * l_MCh(K)(J)); --MB * MCh
                -- Sum2 := Sum2 + (l_MO(I)(K) * l_MEh(K)(J)); -- MO * MEh
              -- end loop;
              -- l_MAh(I)(J) := Sum1 + Sum2 * l_a; -- Sum1 + Sum2 * aa;
            -- end loop;
          -- end loop;  
          -- Output(l_MCh);      
          Put_Line("Exit: Calculate procedure for T"& Integer'Image(I));       
        end;
        ------
        -- Передати МАн у Т1
        accept Result(r_MAh: out Proto_Matrix) do
          Put_Line("Sent Data");
          Fill(l_MAh);
          r_MAh := l_MAh;
        end Result;
      end; 
      Put_Line("Task T" & Integer'Image(I) &" finished");    
    end TX;
  
  begin
    -- Initialize MA
    -- Fill(MA);
    -- Enter MB, MC, MO, ME, a
    -- Put_Line("MB =   "); Input(MB); 
    -- Put_Line("MC =   "); Input(MC); 
    -- Put_Line("MO =   "); Input(MO); 
    -- Put_Line("ME =   "); Input(ME);      
    -- Put_Line("a =    "); Input(a); Put(a); Put_Line("");    
    
    -- for I in Range_2P loop
      -- B := (H*(I-1) + 1);
      -- E := (H*I);
      -- if (I = P) then
        -- E := N;
      -- end if;
      -- Calculate(MB, MC, MO, ME, a, MA);
    -- end loop;
    
    -- Put_Line("MA =   "); Output(MA);
    
    T1_T := new T1;
    for I in Range_2P loop
      -- Put(I); Put_Line("");
      TX_Arr(I) := new TX(I);
    end loop;
  end;
  
end p03;