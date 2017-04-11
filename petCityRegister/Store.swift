//
//  StoreObject.swift
//  Pet-Hotels
//
//  Created by Owner on 2016. 12. 25..
//  Copyright © 2016년 TwistWorld. All rights reserved.
//

import UIKit
import CoreLocation

/// An object to store all the details of the Store that we want to display.
class Store: NSObject {

    var objectId: String?
    /// 스토어의 이름
    var name: String?
    /// 스토어 주소
    var address: String?
    /// 스토어 전화번호
    var phoneNumber: String?
    /// 스토어의 짧은 디스크립션
    var storeDescription: String?
    /// 서브 타이틀
    var storeSubtitle: String?
    /// 웹사이트
    var website: String?
    /// 현재 위치와의 거리
    var distance: Double?
    /// 지오 포인트
    var location: GeoPoint?
    /// 이메일 주소
    var emailAddress: String?
    /// 메인 이미지
    var imageURL: String?
    /// 사진 섹션에 배치되는 사진들 링크 - ','로 구분됨
    var imageArray: String?
    
    /// 서비스 카테고리 
    var serviceCategory: String? 
    /// 영업 시간
    var operationTime: String?
    /// 서비스 가능한 반려동물 품종 - 개, 고양이 등
    var serviceablePet: String?
    /// 반려동물 크기 - 대형, 중형, 소형 등
    var petSize: String?
    /// 가격 정보
    var priceInfo: String?
    /// 참고 사항
    var note: String?
    /// 좋아요 리스트에 추가한 사용자들 정보
    var favoriteList: [BackendlessUser] = []
    
    /// 몇 명의 사용자가 봤는지
    var hits: Int = 0
    /// 제휴 여부 
    var isAffiliated: Bool = false
    /// 인증 여부
    var isVerified: Bool = false
    /// 광고 여부
    var isAdvertising: Bool = false
    

    /**
     Creates a coordinate of the Store from the location object, if no location object is found, creates a 0,0 coordinate

     - returns: coordinate of the Store
     */
    func coordinate() -> CLLocationCoordinate2D {
        if location != nil {
            return CLLocationCoordinate2DMake(location!.latitude.doubleValue, location!.longitude.doubleValue)
        }
        return CLLocationCoordinate2DMake(0, 0)
    }


}
