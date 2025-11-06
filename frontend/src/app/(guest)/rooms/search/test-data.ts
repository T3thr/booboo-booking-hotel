// Test data for room search page development and testing
import { RoomSearchResult } from '@/types';

export const mockRoomSearchResults: RoomSearchResult[] = [
  {
    room_type_id: 1,
    name: 'Deluxe Room',
    description: 'ห้องพักหรูหราพร้อมวิวเมือง เตียงคิงไซส์ และสิ่งอำนวยความสะดวกครบครัน',
    max_occupancy: 2,
    default_allotment: 10,
    amenities: [
      { amenity_id: 1, name: 'WiFi ฟรี' },
      { amenity_id: 2, name: 'เครื่องปรับอากาศ' },
      { amenity_id: 3, name: 'ทีวีจอแบน' },
      { amenity_id: 4, name: 'มินิบาร์' },
      { amenity_id: 5, name: 'ห้องน้ำส่วนตัว' },
    ],
    available_rooms: 5,
    total_price: 3000.00,
    nightly_prices: [
      { date: '2025-02-01', price: 1500.00 },
      { date: '2025-02-02', price: 1500.00 },
    ],
  },
  {
    room_type_id: 2,
    name: 'Suite Room',
    description: 'ห้องสวีทขนาดใหญ่พร้อมห้องนั่งเล่นแยก เหมาะสำหรับครอบครัว',
    max_occupancy: 4,
    default_allotment: 5,
    amenities: [
      { amenity_id: 1, name: 'WiFi ฟรี' },
      { amenity_id: 2, name: 'เครื่องปรับอากาศ' },
      { amenity_id: 3, name: 'ทีวีจอแบน' },
      { amenity_id: 4, name: 'มินิบาร์' },
      { amenity_id: 5, name: 'ห้องน้ำส่วนตัว' },
      { amenity_id: 6, name: 'ห้องนั่งเล่น' },
      { amenity_id: 7, name: 'ระเบียง' },
    ],
    available_rooms: 3,
    total_price: 5000.00,
    nightly_prices: [
      { date: '2025-02-01', price: 2500.00 },
      { date: '2025-02-02', price: 2500.00 },
    ],
  },
  {
    room_type_id: 3,
    name: 'Standard Room',
    description: 'ห้องพักมาตรฐานสะดวกสบาย เหมาะสำหรับนักเดินทางคนเดียว',
    max_occupancy: 2,
    default_allotment: 20,
    amenities: [
      { amenity_id: 1, name: 'WiFi ฟรี' },
      { amenity_id: 2, name: 'เครื่องปรับอากาศ' },
      { amenity_id: 3, name: 'ทีวีจอแบน' },
      { amenity_id: 5, name: 'ห้องน้ำส่วนตัว' },
    ],
    available_rooms: 10,
    total_price: 2000.00,
    nightly_prices: [
      { date: '2025-02-01', price: 1000.00 },
      { date: '2025-02-02', price: 1000.00 },
    ],
  },
];

export const mockRoomSearchResultsWithVariedPricing: RoomSearchResult[] = [
  {
    room_type_id: 1,
    name: 'Deluxe Room',
    description: 'ห้องพักหรูหราพร้อมวิวเมือง',
    max_occupancy: 2,
    default_allotment: 10,
    amenities: [
      { amenity_id: 1, name: 'WiFi ฟรี' },
      { amenity_id: 2, name: 'เครื่องปรับอากาศ' },
    ],
    available_rooms: 5,
    total_price: 4500.00,
    nightly_prices: [
      { date: '2025-02-01', price: 1500.00 },
      { date: '2025-02-02', price: 2000.00 }, // Weekend rate
      { date: '2025-02-03', price: 1000.00 }, // Weekday rate
    ],
  },
];

export const mockEmptyResults: RoomSearchResult[] = [];

