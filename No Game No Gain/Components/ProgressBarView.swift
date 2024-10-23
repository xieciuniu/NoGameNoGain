//
//  ProgressBarView.swift
//  No Game No Gain
//
//  Created by Hubert Wojtowicz on 07/08/2024.
//

import SwiftUI

struct ProgressBarView: View {
    let userLevel: Int = 5
    let expToNextLevel: Double = 100
    let expCurrent: Double = 10
    
    var body: some View {
        VStack{
//            HStack {
//                ZStack{
//                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
//                                    .cornerRadius(20)
//                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
//                    VStack{
//                        Text(String(userLevel))
//                            .font(.system(size: 30, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.white)
//                            .shadow(color: .black, radius: 2, x: 2, y: 2)
//                        
//                        Text("Level")
//                            .font(.system(size: 20, weight: .heavy, design: .rounded))
//                    }
//                }
//                .frame(width: 80, height: 80)
//    //            .padding()
//                
//                VStack{
//                    Spacer()
//                    ProgressView(value: expCurrent, total: expToNextLevel)
//                        .progressViewStyle(LinearProgressViewStyle())
////                        .scaleEffect(x: 1, y: 4, anchor: .center)
//    //                    .padding()
//                    Spacer()
//                    
//                    HStack{
//                        Spacer()
//                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
//                    }
//                    Spacer()
//                }
//                .padding()
//            }
//            .frame(height: 100)
//            .padding()
            
            
            HStack {
                ZStack{
                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
                                    .cornerRadius(20)
                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
                    VStack{
                        Text(String(userLevel))
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                        
                        Text("Level")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                    }
                }
                .frame(width: 80, height: 80)
    //            .padding()
                
                VStack{
                    Spacer()
                    ProgressView(value: expCurrent, total: expToNextLevel)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1, y: 2, anchor: .center)
    //                    .padding()
                    Spacer()
                    
                    HStack{
                        Spacer()
                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
                    }
                    Spacer()
                }
                .padding()
            }
            .frame(height: 100)
            .padding()
            
            
            
//            HStack {
//                ZStack{
//                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
//                                    .cornerRadius(20)
//                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
//                    VStack{
//                        Text(String(userLevel))
//                            .font(.system(size: 30, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.white)
//                            .shadow(color: .black, radius: 2, x: 2, y: 2)
//                        
//                        Text("Level")
//                            .font(.system(size: 20, weight: .heavy, design: .rounded))
//                    }
//                }
//                .frame(width: 80, height: 80)
//    //            .padding()
//                
//                VStack{
//                    Spacer()
//                    ProgressView(value: expCurrent, total: expToNextLevel)
//                        .progressViewStyle(LinearProgressViewStyle())
//                        .scaleEffect(x: 1, y: 3, anchor: .center)
//    //                    .padding()
//                    Spacer()
//                    
//                    HStack{
//                        Spacer()
//                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
//                    }
//                    Spacer()
//                }
//                .padding()
//            }
//            .frame(height: 100)
//            .padding()
//            
//            
//            HStack {
//                ZStack{
//                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
//                                    .cornerRadius(20)
//                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
//                    VStack{
//                        Text(String(userLevel))
//                            .font(.system(size: 30, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.white)
//                            .shadow(color: .black, radius: 2, x: 2, y: 2)
//                        
//                        Text("Level")
//                            .font(.system(size: 20, weight: .heavy, design: .rounded))
//                    }
//                }
//                .frame(width: 80, height: 80)
//    //            .padding()
//                
//                VStack{
//                    Spacer()
//                    ProgressView(value: expCurrent, total: expToNextLevel)
//                        .progressViewStyle(LinearProgressViewStyle())
//                        .scaleEffect(x: 1, y: 4, anchor: .center)
//    //                    .padding()
//                    Spacer()
//                    
//                    HStack{
//                        Spacer()
//                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
//                    }
//                    Spacer()
//                }
//                .padding()
//            }
//            .frame(height: 100)
//            .padding()
//            
//            
//            HStack {
//                ZStack{
//                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
//                                    .cornerRadius(20)
//                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
//                    VStack{
//                        Text(String(userLevel))
//                            .font(.system(size: 30, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.white)
//                            .shadow(color: .black, radius: 2, x: 2, y: 2)
//                        
//                        Text("Level")
//                            .font(.system(size: 20, weight: .heavy, design: .rounded))
//                    }
//                }
//                .frame(width: 80, height: 80)
//    //            .padding()
//                
//                ZStack{
//                    Spacer()
//                    ProgressView(value: expCurrent, total: expToNextLevel)
//                        .progressViewStyle(LinearProgressViewStyle())
//                        .scaleEffect(x: 1, y: 4, anchor: .center)
//    //                    .padding()
//                    Spacer()
//                    
//                    HStack{
////                        Spacer()
//                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
//                            .padding()
//                        Spacer()
//                    }
//                    Spacer()
//                }
//                .padding()
//            }
//            .frame(height: 100)
//            .padding()
            
            
//            HStack {
//                ZStack{
//                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .center, endPoint: .bottomTrailing)
//                                    .cornerRadius(20)
//                                    .shadow(color: .black, radius: 10, x: 0, y: 10)
//                    VStack{
//                        Text(String(userLevel))
//                            .font(.system(size: 30, weight: .heavy, design: .rounded))
//                            .foregroundStyle(.white)
//                            .shadow(color: .black, radius: 2, x: 2, y: 2)
//                        
//                        Text("Level")
//                            .font(.system(size: 20, weight: .heavy, design: .rounded))
//                    }
//                }
//                .frame(width: 80, height: 80)
//    //            .padding()
//                
//                ZStack{
//                    Spacer()
//                    ProgressView(value: expCurrent, total: expToNextLevel)
//                        .progressViewStyle(LinearProgressViewStyle())
//                        .scaleEffect(x: 1, y: 7, anchor: .center)
//    //                    .padding()
//                    Spacer()
//                    
//                    HStack{
//                        Text("\(expCurrent.formatted()) / \(expToNextLevel.formatted())")
//                            .padding(.leading, 5)
//                            .hoverEffect()
//                        Spacer()
//                    }
//                    Spacer()
//                }
//                .padding()
//                .padding(.bottom, 30)
//            }
//            .frame(height: 100)
//            .padding()
        }
    }
}

#Preview {
    ProgressBarView()
}
