#include "modelica_array.hpp"
#include "numerical_array.hpp"

int main(int argc,char* argv[])
{
  std::cout << "test" << endl;

  integer_array arr1 = fill_array(10,std::vector<int>(1,3));
 //  real_array arr;
//   real_array arr2(std::vector<int>(2,2));
//   real_array arr3(std::vector<int>(2,2),std::vector<double>(4,1.1));
//   real_array arr4(std::vector<int>(1,3),std::vector<double>(3,2));

//   // arr.print_dims();
//   //arr2.print_dims();
//   //arr3.print_dims();

//   real_array arr5;
//   arr5 = diagonal(arr4);

//   integer_array arr6;
//   arr6 = identity_matrix(4);

//   integer_array arr7 = zeros(std::vector<int>(2,2));
//   //  arr6 = modelica_identity(4);
//   cout << "ndims of arr3 : " << arr3.ndims() << endl;
//   cout << "max of arr3 : " << arr3.max() << endl;
//   cout << "product of arr3 : " << arr3.product() << endl;
//   cout << "sum of arr3 : " << arr3.sum() << endl;
//   cout << "sum of arr4 : " << arr4.sum() << endl;
//   arr4.print_data();
//   cout << "data in arr5 : " << endl;
//   arr5.print_data();
//   cout << "sum of arr5 : " << arr5.sum() << endl;
//   arr6.print_data();
//   cout << "data in arr7 : " << endl;
//   arr7.print_data();

//   //integer_array arr8;
//   std::vector<int> data;
//   data.push_back(1);
//   data.push_back(2);
//   data.push_back(3);

//   integer_array arr8 = create_array(data);
// //arr8 = fill_array(17.0,std::vector<int>(2,2));
// //   cout << "data in arr8" << endl;
// //   arr8.print_data();
  return 1;
}
